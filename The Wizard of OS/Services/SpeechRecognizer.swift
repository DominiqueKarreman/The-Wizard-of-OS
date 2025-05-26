import AVFoundation
import Foundation
import Speech
import SwiftUI
import CoreData

#if os(macOS)
import AppKit

#else
import UIKit
#endif

public enum ListeningState: String {
    case idle
    case collectingPrompt
    case processingPrompt
}

class SpeechRecognizer: NSObject, ObservableObject {
    @AppStorage("voicePromptMode") private var voicePromptMode: String = "button"
    @AppStorage("pauseDuration") private var pauseDuration: Double = 2
    private var lastSpokenDate: Date?
    private var pauseTimer: Timer?
    
    @AppStorage("videoModeActive") var videoModeActive: Bool = false
    @AppStorage("screenshotModeActive") var screenshotModeActive: Bool = false
    
    private var context: NSManagedObjectContext
    var sendPromptAction: ((String, NSManagedObjectContext, PlatformImage?) -> Void)?
    
    private var videoSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var videoQueue = DispatchQueue(label: "VideoQueue")
    private var latestFrame: CGImage?

    // Existing properties and methods
    
    // Modify the init method to accept the context
    init(context: NSManagedObjectContext, sendPromptAction: ((String, NSManagedObjectContext, PlatformImage?) -> Void)? = nil) {
        self.context = context
        self.sendPromptAction = sendPromptAction
        super.init()
        startVideoCaptureSession()
    }
    
    @Published var voiceStatus: ListeningState = .idle  // Correct initialization here
    
    
    private class SpeechAssist {
        var audioEngine: AVAudioEngine?
        var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
        var recognitionTask: SFSpeechRecognitionTask?
        let speechRecognizer = SFSpeechRecognizer()
        
       
        deinit {
            reset()
        }

        func reset() {
            recognitionTask?.cancel()
            audioEngine?.stop()
            audioEngine = nil
            recognitionRequest = nil
            recognitionTask = nil
        }
    }

    private let assistant = SpeechAssist()

    func record(to speech: Binding<String>, audioLevel: Binding<Double>) {
        #if os(iOS)
        let microphoneAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        let speechAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        #elseif os(macOS)
        let microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        let speechAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        #endif

        if microphoneAuthorized && speechAuthorized {
            // If permissions are already granted, start recording
            startRecording(to: speech, audiolevel: audioLevel)  // Use audioLevel directly
        } else {
            requestMicrophonePermission { microphonePermissionGranted in
                if microphonePermissionGranted {
                    self.requestSpeechRecognitionPermission { speechPermissionGranted in
                        if speechPermissionGranted {
                            self.startRecording(to: speech, audiolevel: audioLevel)  // Use self
                        } else {
                            self.relay(speech, message: "Speech recognition access denied")  // Use self
                            self.showPermissionDeniedAlert(for: .speech)  // Use self
                        }
                    }
                } else {
                    self.relay(speech, message: "Microphone access denied")  // Use self
                    self.showPermissionDeniedAlert(for: .microphone)  // Use self
                }
            }
        }
    }

    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        #if os(iOS)
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            completion(granted)
        }
        #elseif os(macOS)
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            completion(granted)
        }
        #endif
    }

    func stopRecording() {
        pauseTimer?.invalidate()
        pauseTimer = nil
        voiceStatus = .idle
        assistant.reset()
    }

    private func startRecording(to speech: Binding<String>, audiolevel: Binding<Double>) {
        assistant.audioEngine = AVAudioEngine()
        guard let audioEngine = assistant.audioEngine else {
            fatalError("Unable to create audio engine")
        }

        assistant.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = assistant.recognitionRequest else {
            fatalError("Unable to create recognition request")
        }

        recognitionRequest.shouldReportPartialResults = true

        do {
            self.relay(speech, message: "Booting audio subsystem")  // Use self

            // Step 1: Configure AVAudioSession for recording
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            #endif

            // Step 2: Set up the audio input node and format
            let inputNode = audioEngine.inputNode
            self.relay(speech, message: "Found input node")  // Use self

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                // Calculate the audio level (volume) from the audio buffer
                let level = self.calculateAudioLevel(from: buffer)
                let normalized = self.normalizedAudioLevel(from: level)
                
//                print("\(level) & \(normalized)")
                DispatchQueue.main.async {
                    audiolevel.wrappedValue = Double(normalized)
                }
                
                recognitionRequest.append(buffer)
            }

            self.relay(speech, message: "Preparing audio engine")  // Use self
            audioEngine.prepare()
            try audioEngine.start()

            // Step 3: Start recognition task
            assistant.recognitionTask = assistant.speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                if var result = result {
                    var transcript = result.bestTranscription.formattedString
                    self.relay(speech, message: transcript)  // Use self
                    
                    if self.voicePromptMode == "pause" && self.voiceStatus == .collectingPrompt {
                        self.lastSpokenDate = Date()
                        self.pauseTimer?.invalidate()
                        self.pauseTimer = Timer.scheduledTimer(withTimeInterval: self.pauseDuration, repeats: false) { _ in
                            guard let lastDate = self.lastSpokenDate, Date().timeIntervalSince(lastDate) >= self.pauseDuration else { return }

                            DispatchQueue.main.async {
                                self.handleFinishedPrompt(transcript: transcript, speech: speech, audioLevel: audiolevel)
                                print("🕒 Auto-handled prompt after \(self.pauseDuration)s of silence.")
                            }
                        }
                    }
                    
                    self.checkForByeMerlin(in: &transcript, speech: speech, result: &result, audioLevel: audiolevel)  // Use self
                    self.checkForHeyMerlin(in: &transcript, speech: speech, result: &result)  // Use self
                    
                    isFinal = result.isFinal
                    print("this is now the transcript: \(transcript)")
                }

                if error != nil || isFinal {
                    audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.assistant.recognitionRequest = nil
                }
            }
        } catch {
            print("Error transcribing audio: \(error.localizedDescription)")
            assistant.reset()
        }
    }

    let heyMerlinRegex = try! NSRegularExpression(pattern: #"(?i)\bHey Merlin\b"#)
    let byeMerlinRegex = try! NSRegularExpression(pattern: #"(?i)\bGoodbye Merlin\b"#)
    
    func checkForHeyMerlin(in transcript: inout String, speech: Binding<String>, result: inout SFSpeechRecognitionResult) {
        guard voiceStatus == .idle else { return }
        let range = NSRange(transcript.startIndex..., in: transcript)
        if heyMerlinRegex.firstMatch(in: transcript, options: [], range: range) != nil {
            voiceStatus = .collectingPrompt
            transcript = ""
            result = SFSpeechRecognitionResult()
            self.relay(speech, message:"")

            
            print("🔊 Detected 'Hey Merlin'. Switched to collectingPrompt state.")
            transcript = "" // Clear transcript immediately to avoid retriggers
        }
    }

    func checkForByeMerlin(in transcript: inout String, speech: Binding<String>, result: inout SFSpeechRecognitionResult, audioLevel: Binding<Double>) {
        guard voiceStatus == .collectingPrompt else { return }
        let range = NSRange(transcript.startIndex..., in: transcript)
        if byeMerlinRegex.firstMatch(in: transcript, options: [], range: range) != nil {
            if let match = heyMerlinRegex.firstMatch(in: transcript, options: [], range: range) {
                let afterMatchIndex = transcript.index(transcript.startIndex, offsetBy: match.range.upperBound)
                transcript = String(transcript[afterMatchIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            result = SFSpeechRecognitionResult()
            handleFinishedPrompt(transcript: transcript, speech: speech, audioLevel: audioLevel)
            transcript = ""
        }
    }

public func handleFinishedPrompt(transcript: String, speech: Binding<String>, audioLevel: Binding<Double>) {
    voiceStatus = .processingPrompt

    var cleanedTranscript = transcript
    let range = NSRange(cleanedTranscript.startIndex..., in: cleanedTranscript)
    if let heyMatch = heyMerlinRegex.firstMatch(in: cleanedTranscript, options: [], range: range) {
        let afterHeyIndex = cleanedTranscript.index(cleanedTranscript.startIndex, offsetBy: heyMatch.range.upperBound)
        cleanedTranscript = String(cleanedTranscript[afterHeyIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // if let match = byeMerlinRegex.firstMatch(in: cleanedTranscript, options: [], range: range) {
    //     let beforeByeIndex = cleanedTranscript.index(cleanedTranscript.startIndex, offsetBy: match.range.lowerBound)
    //     cleanedTranscript = String(cleanedTranscript[..<beforeByeIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
    // }

#if os(macOS)
    let snapshot: PlatformImage? = screenshotModeActive ? captureScreenSnapshot() : (videoModeActive ? captureWebcamSnapshot() : nil)
#else
    let snapshot: PlatformImage? = nil
#endif

    sendPromptAction?(cleanedTranscript, context, snapshot)
    print("sending prompt, cleaned transcript: \(cleanedTranscript)")
    self.relay(speech, message: "")

    if let audioEngine = assistant.audioEngine, audioEngine.isRunning {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    assistant.reset()

    print("🔊 Detected 'Goodbye Merlin'. Switched to processingPrompt state. transcript: \(cleanedTranscript)")

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.voiceStatus = .idle
        self.record(to: speech, audioLevel: audioLevel)
    }
}
    
    func stopAndRestartRecording(to speech: Binding<String>, audiolevel: Binding<Double>, delay: TimeInterval = 1.0) {
        stopRecording()  // Stop the current recording

        // Wait for the specified delay and restart the recording
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.startRecording(to: speech, audiolevel: audiolevel)  // Restart the recording
        }
    }
    private func resetSystemForNextActivation() {
        // Reset any necessary components here to make the system ready for the next "Hey Merlin"
        
        assistant.reset()  // Reset the assistant
//        voiceStatus = .idle  // Set the voice status back to idle
        print("🔄 System reset. Ready to listen for the next 'Hey Merlin'.")
    }
    
    func normalizedAudioLevel(from decibels: Float) -> Float {
        let minDb: Float = -80
        let maxDb: Float = -20
        let clamped = max(min(decibels, maxDb), minDb)  // Clamp to valid range
        return (clamped - minDb) / (maxDb - minDb)       // Normalize to 0...1
    }

    // Helper method to calculate audio level
    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) -> Float {
        let channelCount = buffer.format.channelCount
        let frameCount = buffer.frameLength
        let channelData = buffer.floatChannelData!

        var totalAmplitude: Float = 0.0
        for channel in 0..<Int(channelCount) {
            let channelDataPointer = channelData[channel]
            for frame in 0..<Int(frameCount) {
                totalAmplitude += abs(channelDataPointer[frame])
            }
        }

        let averageAmplitude = totalAmplitude / Float(Int(frameCount) * Int(channelCount))

        // Optionally convert the amplitude to a decibel value if needed
        let audioLevel = 20 * log10(averageAmplitude)

        return audioLevel
    }

    private func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            completion(status == .authorized)
        }
    }

    enum PermissionType {
        case microphone
        case speech
    }

    private func showPermissionDeniedAlert(for type: PermissionType) {
        #if os(macOS)
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "\(type == .microphone ? "Microphone" : "Speech Recognition") Access Denied"
            alert.informativeText = "Please enable it in System Settings."
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn,
               let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_\(type == .microphone ? "Microphone" : "SpeechRecognition")") {
                NSWorkspace.shared.open(url)
            }
        }
        #endif
        // On iOS, typically we handle this by presenting a UI alert or redirecting the user
    }

    private func relay(_ binding: Binding<String>, message: String) {
        DispatchQueue.main.async {
            binding.wrappedValue = message
        }
    }

#if os(macOS)
    private func captureWebcamSnapshot() -> PlatformImage? {
        guard let cgImage = latestFrame else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
#else
    private func captureWebcamSnapshot() -> PlatformImage? {
        // Webcam snapshot capture not implemented for iOS
        return nil
    }
#endif
    
    func startVideoCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("❌ Unable to access video device")
            return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: videoQueue)
        session.addOutput(output)

        self.videoSession = session
        self.videoOutput = output
        session.startRunning()
    }
}

extension SpeechRecognizer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            self.latestFrame = cgImage
        }
    }
}

// MARK: - Screen Snapshot for macOS
#if os(macOS)
private func captureScreenSnapshot() -> PlatformImage? {
    guard let screen = NSScreen.main else { return nil }
    let image = CGWindowListCreateImage(screen.frame, .optionOnScreenBelowWindow, kCGNullWindowID, .bestResolution)
    if let cgImage = image {
        return NSImage(cgImage: cgImage, size: screen.frame.size)
    }
    return nil
}
#endif

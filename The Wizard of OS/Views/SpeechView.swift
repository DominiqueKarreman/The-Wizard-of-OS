import SwiftUI
import Speech
import SiriWaveView
import CoreData

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct SpeechView: View {
    @State var voiceStatus: ListeningState = .idle
    @State var currentPrompt: String = ""
    
    @AppStorage("voicePromptMode") private var voicePromptMode: String = "button"
    @AppStorage("videoModeActive") var videoModeActive: Bool = false
    
    @State private var hoveredMessageID: UUID? = nil
    @State private var isThinking = false // Track if the assistant is thinking
    // Variable to store the thinking content
    
    @State private var filteredPrompt: String = ""
    
    @State var textValue: String = "Press start to record speech..."
    @StateObject var speechRecognizer: SpeechRecognizer
    
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var messageListVM: ChatMessageListViewModel
    var streamingApiClient: StreamingAPIClient!
    
    let heyMerlinRegex = try! NSRegularExpression(pattern: #"(?i)\bHey Merlin\b"#)
    let byeMerlinRegex = try! NSRegularExpression(pattern: #"(?i)\bGoodbye Merlin\b"#)
    
    @State private var spokenText: String = ""
    @State var voicePrompt: String = ""
    @State private var isRecording: Bool = false
    @State private var audioLevel: Double = 0.0 // Store the audio level for the wave
    @State private var isEditingTranscript: Bool = false

    init(context: NSManagedObjectContext, messageListVM: ChatMessageListViewModel, streamingApiClient: StreamingAPIClient) {
        streamingApiClient.chatMessageListVM = messageListVM
       
        _speechRecognizer = StateObject(wrappedValue: SpeechRecognizer(
            context: context,
            sendPromptAction: { prompt, ctx, image in
                do {
                    
                    
                    try messageListVM.addMessage(message: prompt, sender: "User", mode: "voice", image: image)
                    try messageListVM.isStreaming = true
                    try streamingApiClient.streamResponse(for: prompt, image: image ?? nil, mode: .voice)
                    print("✅ Streaming request sent")
                } catch {
                    print("❌ Error sending prompt: \(error.localizedDescription)")
                }
            }
        ))
        self._context = Environment(\.managedObjectContext)
        streamingApiClient.voiceStatus = voiceStatus
        self.streamingApiClient = streamingApiClient
       
    }
    
    var body: some View {
        VStack(spacing: 50) {
            // Conditionally include the camera preview at the top if video mode is active
            if videoModeActive {
                CameraPreview()
                    .frame(width: 640, height: 360)
                    .cornerRadius(12)
                    
            }

            // Add the SiriWaveView
            if speechRecognizer.voiceStatus == ListeningState.collectingPrompt {
                SiriWaveView(power: $audioLevel)  // Amplitude driven by the audio level
                    .frame(height: 100)
                    .padding(.top, 20).frame(minWidth: 0, maxWidth: 1500)
            }
            ScrollViewReader { proxy in
                VStack {
                    List(messageListVM.voiceMessages, id: \.id) { message in
                        MessageRow(
                            message: message, thinkingContent: nil,
                            tempMessage: nil,
                            hoveredMessageID: hoveredMessageID,
                            deleteMessage: deleteMessage,
                            saveMessage: saveMessage,
                            setHoveredMessage: { newID in hoveredMessageID = newID }
                        )
                        .listRowBackground(Color.clear)
                    }

                    // Show the tempMessage if it's not empty
                    if let tempVoiceMessage = messageListVM.tempVoiceAssistantMessage, !tempVoiceMessage.message.isEmpty, !isThinking {
                        MessageRow(
                            message: nil, thinkingContent: nil,
                            tempMessage: tempVoiceMessage,
                            hoveredMessageID: hoveredMessageID,
                            deleteMessage: deleteMessage,
                            saveMessage: saveMessage,
                            setHoveredMessage: { newID in hoveredMessageID = newID }
                        )
                        .listRowBackground(Color.clear)
                    }

                    // Show a loading spinner (ProgressView) if the assistant is thinking
                    if isThinking {
                        HStack {
                            Text("Thinking very hard")
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5, anchor: .center) // Adjust size of the spinner
                                .padding()
                            Spacer()
                        }
                        .transition(.opacity) // Add fade transition for smooth animation
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
//                    .onChange(of: messageListVM.voiceMessages.count) { _ in
//                        scrollToLastMessage(proxy)
//                    }
//                    .onChange(of: lastMerlinMessage) { _ in
//                        scrollToLastMessage(proxy)
//                    }
//                    .onChange(of: messageListVM.tempAssistantMessage?.message) { _ in
//                        handleThinkingState() // Check for thinking state whenever the tempMessage changes
//                    }
            }

            Image(systemName: isRecording ? "mic.fill" : "mic")
                .imageScale(.large)
                .scaleEffect(2.0)
                .foregroundColor(isRecording ? .accentColor : .primary)
            if speechRecognizer.voiceStatus == ListeningState.collectingPrompt {
                HStack {

                    if isEditingTranscript {
                        TextField("Speak now...", text: Binding(
                            get: {
                                let pattern = #"(?i)\bHey Merlin\b"#
                                if let range = textValue.range(of: pattern, options: .regularExpression) {
                                    return textValue[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                                return ""
                            },
                            set: { newValue in
                                let pattern = #"(?i)\bHey Merlin\b"#
                                if let range = textValue.range(of: pattern, options: .regularExpression) {
                                    textValue = textValue[..<range.upperBound] + " " + newValue
                                } else {
                                    textValue = newValue
                                }
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                        Button(action: {
                            isEditingTranscript = false
                               voicePrompt = textValue
                            DispatchQueue.main.async  {
                                speechRecognizer.handleFinishedPrompt(transcript: voicePrompt, speech: $textValue, audioLevel: $audioLevel)
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.green)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.trailing)
                    } else {
                        HStack {
                            Text({
                                let pattern = #"(?i)\bHey Merlin\b"#
                                if let range = textValue.range(of: pattern, options: .regularExpression) {
                                    return textValue[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                                return ""
                            }())
                            .padding(.horizontal)
                           if voicePromptMode == "button" {
                                Button(action: {
                                    if let range = textValue.range(of: #"(?i)\bHey Merlin\b"#, options: .regularExpression) {
                                        let promptOnly = textValue[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                                        voicePrompt = String(promptOnly)
                                    } else {
                                        voicePrompt = textValue
                                    }
                                    speechRecognizer.stopRecording()
                                    speechRecognizer.handleFinishedPrompt(transcript: voicePrompt, speech: $textValue, audioLevel: $audioLevel)
                                }) {
                                    Label("Send Prompt", systemImage: "paperplane.fill")
                                        .foregroundColor(.white)
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .padding(.trailing)
                            }
                        }
                    }

                    Button(action: {
                        isEditingTranscript.toggle()
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.trailing)
                }
            }
//                if let tempMessage = messageListVM.tempVoiceAssistantMessage {
//                    MessageRow(
//                        message: nil, thinkingContent: nil,
//                        tempMessage: tempMessage,
//                        hoveredMessageID: hoveredMessageID,
//                        deleteMessage: deleteMessage,
//                        saveMessage: saveMessage,
//                        setHoveredMessage: { newID in hoveredMessageID = newID }
//                    )
//                    .transition(.move(edge: .bottom))
//                    .animation(.easeInOut(duration: 0.1), value: messageListVM.tempVoiceAssistantMessage?.message)
//                    .listRowBackground(Color.clear)
//
//                }
//                if !isRecording {
//                    Button {
//                        print("starting speech recognition")
//                        self.textValue = ""
//                        self.spokenText = ""
//                        isRecording = true
//                        speechRecognizer.record(to: $textValue, audioLevel: $audioLevel)
//                    } label: {
//                        Text("Start")
//                    }
//                } else {
//                    Button {
//                        print("stopping speech recognition")
//                        isRecording = false
//                        audioLevel = 0
//                        spokenText = textValue
//                        speechRecognizer.stopRecording()
//                        textValue = "Press start to record speech..."
//                        print(spokenText)
//
//                        // Check for "Goodbye Merlin" after stopping recording
//
//                    } label: {
//                        Text("Stop")
//                    }
//                }

            if !isRecording {
                Text({
                    let pattern = #"(?i)\bHey Merlin\b"#
                    if let range = textValue.range(of: pattern, options: .regularExpression) {
                        let afterHeyMerlin = textValue[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                        return afterHeyMerlin.isEmpty ? spokenText : afterHeyMerlin
                    }
                    return spokenText
                }())
            }
        }
        .onChange(of: spokenText){
            let pattern = #"(?i)\bHey Merlin\b"#
            if let range = spokenText.range(of: pattern, options: .regularExpression) {
                let afterHeyMerlin = spokenText[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                filteredPrompt = afterHeyMerlin
                print("\(filteredPrompt) is the filtered prompt and spokenText is \(spokenText) and textValue is \(textValue)")
            }
        }
        .onChange(of: messageListVM.tempVoiceAssistantMessage?.message) { _ in
            handleThinkingState() // Check for thinking state whenever the tempMessage changes
        }
        .onAppear(){
            self.textValue = ""
            self.spokenText = ""
            isRecording = true
            speechRecognizer.record(to: $textValue, audioLevel: $audioLevel)
        }
        .onDisappear(){
           isRecording = false
           audioLevel = 0
           speechRecognizer.stopRecording()
           textValue = "Press start to record speech..."
           print(spokenText)

           // Check for "Goodbye Merlin" after stopping recording
        }
        .padding()
    }
    private func deleteMessage(_ message: Message) {
        guard let context = message.managedObjectContext else { return }
        
        context.delete(message) // Delete from Core Data
         
        do {
            try context.save() // Save changes
        } catch {
            print("Failed to delete message: \(error.localizedDescription)")
        }

        // Remove from local array
        if let index = messageListVM.messages.firstIndex(where: { $0.id == message.id }) {
            messageListVM.messages.remove(at: index)
        }
    }
    
    private func saveMessage(_ message: Message) {
        // Implement save logic
    }

    // Handle start and end of thinking based on <think> and </think> tags
    private func handleThinkingState() {
        guard let tempMessage = messageListVM.tempVoiceAssistantMessage?.message else { return }

        // Start thinking when <think> is found
        if tempMessage.contains("<think>") && !isThinking {
            isThinking = true
        }

        // Stop thinking when </think> is found
        if tempMessage.contains("</think>") && isThinking {
            // Extract content between <think> and </think>
            if let rangeStart = tempMessage.range(of: "<think>"),
               let rangeEnd = tempMessage.range(of: "</think>") {
                let content = tempMessage[rangeStart.upperBound..<rangeEnd.lowerBound]
                messageListVM.tempVoiceAssistantMessage?.thinkingContent = String(content) // Save the thinking content
                
                print(" */* ", messageListVM.tempVoiceAssistantMessage?.thinkingContent as Any, " */* ", "content van temp message")
                // Remove the <think> and </think> section from the tempMessage
                let cleanedMessage = tempMessage.replacingOccurrences(of: "<think>\(content)</think>", with: "")
                messageListVM.tempVoiceAssistantMessage?.message = cleanedMessage // Update the tempMessage
            }
            isThinking = false
        }
    }
    
    func checkForByeMerlin(in transcript: inout String, audioLevel: Binding<Double>) -> Bool {
        let range = NSRange(transcript.startIndex..., in: transcript)
        print("range:", range)
        if byeMerlinRegex.firstMatch(in: transcript, options: [], range: range) != nil {
            voiceStatus = .processingPrompt  // Switch to processingPrompt state
            
                sendPrompt(transcript, in: context)
            
            print("transcript: before reset \(transcript)")

            transcript = ""  // Reset transcript to avoid re-triggering
            print("transcript: before false \(transcript)")

            return true
        }
        
        return false
        print("transcript: after false \(transcript)")
    }
    public func sendPrompt(_ prompt: String, in context: NSManagedObjectContext) {
        do {
            try messageListVM.addMessage(message: prompt, sender: "User", mode: "voice", image: nil )
            try messageListVM.isStreaming = true
            print("\(messageListVM.isStreaming): state")
            
            try streamingApiClient.streamResponse(for: prompt, image: nil, mode: .voice)
            print("✅ Streaming request sent")
            
            
        } catch {
            print("❌ Error sending prompt: \(error.localizedDescription)")
        }
    
}
    func sendToBackend(_ text: String) {
        // Implement the function to send the `text` to your backend
        print("Sending prompt to backend: \(text)")
        // Your API request logic here
    }
}

//#Preview {
//    SpeechView()
//}

#if os(macOS)
import AVFoundation

struct CameraPreview: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true

        let session = AVCaptureSession()
        session.sessionPreset = .medium

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("❌ Unable to access camera")
            return view
        }

        session.addInput(input)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer?.addSublayer(previewLayer)

        session.startRunning()

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
#else
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let session = AVCaptureSession()
        session.sessionPreset = .medium

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("❌ Unable to access camera")
            return view
        }

        session.addInput(input)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        previewLayer.connection?.videoOrientation = .portrait
        // No autoresizingMask needed on iOS
        view.layer.addSublayer(previewLayer)

        session.startRunning()

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#endif

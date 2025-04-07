import SwiftUI
import Speech
import SiriWaveView

struct SpeechView: View {
    @State var voiceStatus: ListeningState = .idle
    @State var currentPrompt: String = ""
    
    @State var textValue: String = "Press start to record speech..."
    @StateObject var speechRecognizer = SpeechRecognizer() // Initialize without $voiceStatus

    let heyMerlinRegex = try! NSRegularExpression(pattern: #"(?i)\bHey Merlin\b"#)
    let byeMerlinRegex = try! NSRegularExpression(pattern: #"(?i)\bGoodbye Merlin\b"#)
    
    @State private var spokenText: String = ""
    @State private var isRecording: Bool = false
    @State private var audioLevel: Double = 0.0 // Store the audio level for the wave
    
    var body: some View {
        VStack(spacing: 50) {
            // Add the SiriWaveView
            if speechRecognizer.voiceStatus == .collectingPrompt {
                SiriWaveView(power: $audioLevel)  // Amplitude driven by the audio level
                    .frame(height: 100)
                    .padding(.top, 20).frame(minWidth: 0, maxWidth: 1500)
            }
            
            Image(systemName: isRecording ? "mic.fill" : "mic")
                .imageScale(.large)
                .scaleEffect(2.0)
                .foregroundColor(isRecording ? .accentColor : .primary)
            
            Text(isRecording ? textValue : "Press start to record speech...")
            
            if !isRecording {
                Button {
                    print("starting speech recognition")
                    self.textValue = ""
                    self.spokenText = ""
                    isRecording = true
                    speechRecognizer.record(to: $textValue, audioLevel: $audioLevel)
                } label: {
                    Text("Start")
                }
            } else {
                Button {
                    print("stopping speech recognition")
                    isRecording = false
                    audioLevel = 0
                    spokenText = textValue
                    speechRecognizer.stopRecording()
                    textValue = "Press start to record speech..."
                    print(spokenText)
                    
                    // Check for "Goodbye Merlin" after stopping recording
                    if checkForByeMerlin(in: &spokenText) {
                        // Send the captured text to the backend
                        sendToBackend(spokenText)
                        
                        // After sending the prompt to the backend, start recording again
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Delay to simulate processing time
                            self.isRecording = true
                            speechRecognizer.record(to: $textValue, audioLevel: $audioLevel)
                        }
                    }
                } label: {
                    Text("Stop")
                }
            }
            
            if !isRecording {
                Text(spokenText)
            }
        }
        .padding()
    }
    
    func checkForByeMerlin(in transcript: inout String) -> Bool {
        let range = NSRange(transcript.startIndex..., in: transcript)
        if byeMerlinRegex.firstMatch(in: transcript, options: [], range: range) != nil {
            voiceStatus = .processingPrompt  // Switch to processingPrompt state
            return true
        }
        return false
    }
    
    func sendToBackend(_ text: String) {
        // Implement the function to send the `text` to your backend
        print("Sending prompt to backend: \(text)")
        // Your API request logic here
    }
}

#Preview {
    SpeechView()
}

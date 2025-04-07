struct VoicePromptView: View {
    @StateObject private var recognizer = SpeechRecognizer()
    @State private var isRecording = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Transcript:")
                .font(.headline)
            Text(recognizer.transcript)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            Button(action: {
                isRecording.toggle()
                if isRecording {
                    recognizer.startTranscribing()
                } else {
                    recognizer.stopTranscribing()
                }
            }) {
                Label(isRecording ? "Stop Recording" : "Start Recording", systemImage: isRecording ? "stop.circle" : "mic.fill")
                    .padding()
                    .background(isRecording ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            if !recognizer.transcript.isEmpty {
                Button("Send as Prompt") {
                    sendPrompt(recognizer.transcript)
                }
                .padding(.top)
            }
        }
        .padding()
    }

    func sendPrompt(_ prompt: String) {
        // Replace this with your API or addMessage logic
        print("Sending prompt: \(prompt)")
    }
}
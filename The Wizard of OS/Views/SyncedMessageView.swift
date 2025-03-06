//import SwiftUI
//import SwiftData
//
//struct SyncedMessageView: View {
//    @Query private var messages: [Message]
//    @Environment(\.modelContext) private var modelContext  // Access the model context from the environment
//    @State private var messageText: String = ""  // State variable for the input
//
//    init() {
//        _messages = Query(sort: \.timestamp, order: .forward)
//    }
//
//    private func sendMessage() {
//        guard !messageText.isEmpty else { return }
//        
//        let newMessage = Message(message: messageText, sender: "YourSenderName", timestamp: Date())
//
//        do {
//            try modelContext.insert(newMessage)
//            print("Message sent and synced automatically")
//            messageText = ""  // Clear the input after sending
//        } catch {
//            print("Error sending message: \(error.localizedDescription)")
//        }
//    }
//
//    var body: some View {
//        VStack {
//            Text("Synced Messages")
//                .font(.headline)
//
//            List(messages) { message in
//                VStack(alignment: .leading) {
//                    Text("Sender: \(message.sender)")
//                    Text("Message: \(message.message)")
//                    Text("Timestamp: \(message.timestamp.formatted())")
//                }
//            }
//
//            TextField("Enter your message", text: $messageText)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//
//            Button("Send") {
//                sendMessage()
//            }
//            .padding()
//            .buttonStyle(.borderedProminent)
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    SyncedMessageView()
//}

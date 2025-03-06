//import SwiftUI
//
//struct MessageView: View {
////    @StateObject private var viewModel = MessageViewModel()
//    @EnvironmentObject private var viewModel: MessageTestViewModel
//    @State private var newMessage = ""  // State for the new message text
//
//    var body: some View {
//        VStack {
//            List(viewModel.messages) { message in
//                Text(message.message)
//            }
//            
//            if viewModel.messages.isEmpty {
//                Text("No messages")
//            }
//
//            // Add a TextField for typing the message
//            TextField("Enter your message", text: $newMessage)
//                .padding()
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .frame(height: 40).onSubmit {
//                    let message = Message(message: newMessage, sender: "User")
//                    Task {
//                        try await viewModel.addMessage(message: message)  // Send the message
//                    }
//                    newMessage = ""
//                }
//
//            // Button to send the message
//            Button(action: {
//                let message = Message(message: "newMessage", sender: "User")
//                Task {
//                    try await viewModel.addMessage(message: message)  // Send the message
//                }
//                newMessage = ""  // Clear the text field after sending
//            }) {
//                Text("Send Message")
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(8)
//            }
//            .disabled(newMessage.isEmpty)
////            Button(action: {
////                viewModel.fetchMessages()  // Send the message
////               
////            }) {
////                Text("fetch Message")
////                    .padding()
////                    .background(Color.blue)
////                    .foregroundColor(.white)
////                    .cornerRadius(8)
////            }
//            // Disable button if the message is empty
//        }
//        .onAppear {
////            viewModel.fetchMessages()  // Fetch messages when the view appears
//        }
//        .padding()
//#if os(macOS)
//        .frame(width: 600)
//#endif
//    }
//}
//
//#Preview {
//    MessageView().environmentObject(MessageTestViewModel())
//}

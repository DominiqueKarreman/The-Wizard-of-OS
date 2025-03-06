import SwiftUI
import CoreData

struct ContentView2: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Message.timestamp, ascending: true)],
        animation: .default
    ) private var messages: FetchedResults<Message>

    @State private var newMessageText: String = ""
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages, id: \.objectID) { message in
                            MessageBubble(message: message)
                                .id(message.objectID)
                        }
                    }
                    .padding()
                    .onAppear {
                        scrollProxy = proxy
                        scrollToBottom(proxy)
                    }
                }
                .onChange(of: messages.count) { _ in
                    scrollToBottom(proxy)
                }
            }

            Divider()

            HStack {
                TextField("Type a message...", text: $newMessageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 40)

                Button(action: addMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .disabled(newMessageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
    }

    private func addMessage() {
        withAnimation {
            let newMessage = Message(context: viewContext)
            newMessage.timestamp = Date()
            newMessage.message = newMessageText

            do {
                try viewContext.save()
                newMessageText = ""
            } catch {
                print("❌ Core Data save error: \(error)")
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            if let lastMessage = messages.last {
                proxy.scrollTo(lastMessage.objectID, anchor: .bottom)
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            Text(message.message ?? "Unknown message")
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)

            Spacer()
        }
    }
}

#Preview {
    ContentView2().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

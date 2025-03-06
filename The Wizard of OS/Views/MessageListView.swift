import SwiftUI

struct MessageListView: View {
    @ObservedObject var messageListVM: ChatMessageListViewModel
    var messages: FetchedResults<Message>
    @State private var hoveredMessageID: UUID? = nil
    @State private var isThinking = false // Track if the assistant is thinking
    // Variable to store the thinking content

    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                List(messages, id: \.id) { message in
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
                if let tempMessage = messageListVM.tempAssistantMessage, !tempMessage.message.isEmpty, !isThinking {
                    MessageRow(
                        message: nil, thinkingContent: nil,
                        tempMessage: tempMessage,
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
            .onChange(of: messages.count) { _ in
                scrollToLastMessage(proxy)
            }
            .onChange(of: lastMerlinMessage) { _ in
                scrollToLastMessage(proxy)
            }
            .onChange(of: messageListVM.tempAssistantMessage?.message) { _ in
                handleThinkingState() // Check for thinking state whenever the tempMessage changes
            }
        }
    }

    private var lastMerlinMessage: Message? {
        messageListVM.messages.last { $0.sender == "Merlin" }
    }

    private func scrollToLastMessage(_ proxy: ScrollViewProxy) {
        if let lastMessage = messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
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
        guard let tempMessage = messageListVM.tempAssistantMessage?.message else { return }

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
                messageListVM.tempAssistantMessage?.thinkingContent = String(content) // Save the thinking content
                
                print(" */* ", messageListVM.tempAssistantMessage?.thinkingContent as Any, " */* ", "content van temp message")
                // Remove the <think> and </think> section from the tempMessage
                let cleanedMessage = tempMessage.replacingOccurrences(of: "<think>\(content)</think>", with: "")
                messageListVM.tempAssistantMessage?.message = cleanedMessage // Update the tempMessage
            }
            isThinking = false
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}



import SwiftData
import Foundation
import SwiftUI

@Observable
class MessageListModel {
    var messages: [Message] // Automatically fetches data from SwiftData
    private let modelContext: ModelContext
    let context = PersistenceController.shared.container.viewContext
    
    init(modelContext: ModelContext, messages: [Message]) {
        self.modelContext = modelContext
        self.messages = messages
    }

    func addMessage(message: String, sender: String) {
        let newMessage = Message(message: message, sender: sender, context: context, thinkingContent: "", clipbloardContext: "")
//        modelContext.insert(newMessage) // Save to CloudKit-backed SwiftData
        
        try? modelContext.save()  // Persist the change
    }

    func removeMessage(id: UUID) {
        if let messageToDelete = messages.first(where: { $0.id == id }) {
//            modelContext.delete(messageToDelete)
            try? modelContext.save()
        }
    }
}

//
//  Message 2.swift
//  The Wizard of OS
//
//  Created by Dominique Karreman on 3/24/25.
//


import CoreData

struct tempMessage: Identifiable {
    var id: UUID
    var message: String
    var sender: String
    var timestamp: Date
    var thinkingContent: String
}




extension Message {
    convenience init(message: String, sender: String, timestamp: Date = Date(), context: NSManagedObjectContext, thinkingContent:String? ) {
        self.init(context: context)
        self.id = UUID()
        self.message = message
        self.sender = sender
        self.timestamp = timestamp
        self.thinkingContent = thinkingContent
    }
}

extension Message {

    @MainActor
    func saveMessage() {
        
        let context = PersistenceController.shared.container.viewContext

        // Save the context
        do {
            try context.save()
            print("Message saved to Core Data!")
        } catch {
            print("Error saving to Core Data: \(error.localizedDescription)")
        }
    }
}
import Foundation

extension Message {
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self.timestamp ?? Date())
    }
}


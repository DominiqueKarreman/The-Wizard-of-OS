//import Foundation
//import CloudKit
//import SwiftData
//
//@Model
//final class Message: Identifiable {
//    
//    @Attribute var id: UUID = UUID()
//     @Attribute var message: String = ""
//     @Attribute var sender: String = ""
//     @Attribute var timestamp: Date = Date()
//
//    var formattedTimestamp: String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .short
//        formatter.timeStyle = .short
//        return formatter.string(from: timestamp)
//    }
//
//    init(id: UUID = UUID(), message: String, sender: String, timestamp: Date = Date()) {
//        self.id = id
//        self.message = message
//        self.sender = sender
//        self.timestamp = timestamp
//    }
//
//    // MARK: - CloudKit Initializer
//   
//    // MARK: - Codable Conformance
//    @MainActor
//    func deleteMessage() {
//        let database = CKContainer.default().privateCloudDatabase
//        let recordID = CKRecord.ID(recordName: self.id.uuidString)
//
//        // Delete from CloudKit
//        database.delete(withRecordID: recordID) { recordID, error in
//            if let error = error {
//                print("Error deleting from CloudKit: \(error.localizedDescription)")
//            } else {
//                print("Message successfully deleted from CloudKit!")
//            }
//        }
//
//        // Delete from SwiftData
//        deleteFromSwiftData()
//    }
//
//    @MainActor
//    func deleteFromSwiftData() {
//        do {
//            let modelContainer = try ModelContainer(for: Message.self)
//            let context = modelContainer.mainContext
//
//            context.delete(self) // Remove from context
//            try context.save() // Save changes
//
//            print("Message deleted from SwiftData!")
//        } catch {
//            print("Error deleting from SwiftData: \(error.localizedDescription)")
//        }
//    }
//    
//    @MainActor func saveMessage() {
//            // Save to CloudKit
//            saveToCloudKit()
//
//            // Save to SwiftData
////            saveToSwiftData()
//        }
//
//        // Save message to CloudKit
//        func saveToCloudKit() {
//            let record = CKRecord(recordType: "Message")
//            record["id"] = self.id.uuidString as CKRecordValue
//            record["message"] = self.message as CKRecordValue
//            record["sender"] = self.sender as CKRecordValue
//            record["timestamp"] = self.timestamp as CKRecordValue
//
//            let database = CKContainer.default().privateCloudDatabase
//            database.save(record) { record, error in
//                if let error = error {
//                    print("Error saving to CloudKit: \(error.localizedDescription)")
//                } else {
//                    print("Message successfully saved to CloudKit!")
//                }
//            }
//        }
//
//        // Save message to SwiftData
//    @MainActor func saveToSwiftData() {
//            do {
//                let modelContainer = try ModelContainer(for: Message.self)
//                let context = modelContainer.mainContext
//
//                // Insert the message into the context
//                let newMessage = Message(message: self.message, sender: self.sender, timestamp: self.timestamp)
//                try context.save()
//
//                print("Message saved to SwiftData!")
//            } catch {
//                print("Error saving to SwiftData: \(error.localizedDescription)")
//            }
//        }
//}
//
//extension Message {
//    var record: CKRecord {
//        let record = CKRecord(recordType: "Message")
//        record["message"] = message
//        record["sender"] = sender
//        record["timestamp"] = Date()
//        return record
//    }
//}
//
//extension Message {
//    convenience init?(record: CKRecord) {
//        guard let message = record["message"] as? String,
//              let sender = record["sender"] as? String,
//              let timestamp = record["timestamp"] as? Date else {
//            return nil
//        }
//        self.init(message: message, sender: sender, timestamp: timestamp)
//    }
//}

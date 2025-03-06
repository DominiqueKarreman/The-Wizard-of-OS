////
////  CloudKitManager.swift
////  The Wizard of OS
////
////  Created by Dominique Karreman on 3/14/25.
////
//
//
//import CloudKit
//
//class CloudKitManager {
//    private let container: CKContainer
//    private let database: CKDatabase
//
//    init() {
//        self.container = CKContainer.default()
//        self.database = container.publicCloudDatabase
//    }
//
//    // Save a message to CloudKit
//    func saveMessage(_ message: Message, completion: @escaping (Result<CKRecord, Error>) -> Void) {
//        let record = CKRecord(recordType: "Message")
//        record["id"] = message.id.uuidString
//        record["message"] = message.message
//        record["sender"] = message.sender
//        record["timestamp"] = message.timestamp as NSDate
//
//        database.save(record) { savedRecord, error in
//            if let error = error {
//                completion(.failure(error))
//            } else if let savedRecord = savedRecord {
//                completion(.success(savedRecord))
//            }
//        }
//    }
//
//    // Fetch all messages from CloudKit
//    func fetchMessages(completion: @escaping (Result<[Message], Error>) -> Void) {
//        let query = CKQuery(recordType: "Message", predicate: NSPredicate(value: true))
//        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: true)
//        query.sortDescriptors = [sortDescriptor]
//
//        let operation = CKQueryOperation(query: query)
//        var fetchedMessages: [Message] = []
//
//        operation.recordFetchedBlock = { record in
//            if let idString = record["id"] as? String,
//               let message = record["message"] as? String,
//               let sender = record["sender"] as? String,
//               let timestamp = record["timestamp"] as? NSDate {
//                let message = Message(message: message,
//                                      sender: sender)
//                fetchedMessages.append(message)
//            }
//        }
//
//        operation.queryCompletionBlock = { _, error in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                completion(.success(fetchedMessages))
//            }
//        }
//
//        database.add(operation)
//    }
//
//    // Delete a message from CloudKit
//    func deleteMessage(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
//        let predicate = NSPredicate(format: "id == %@", id.uuidString)
//        let query = CKQuery(recordType: "Message", predicate: predicate)
//        let operation = CKQueryOperation(query: query)
//
//        operation.recordFetchedBlock = { record in
//            if let recordToDelete = record {
//                self.database.delete(withRecordID: recordToDelete.recordID) { _, error in
//                    if let error = error {
//                        completion(.failure(error))
//                    } else {
//                        completion(.success(()))
//                    }
//                }
//            }
//        }
//
//        database.add(operation)
//    }
//}

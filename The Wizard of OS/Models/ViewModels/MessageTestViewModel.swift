////
////  MessageTestViewModel.swift
////  The Wizard of OS
////
////  Created by Dominique Karreman on 3/18/25.
////
//
//import SwiftUI
//import CloudKit
//
//@MainActor
//class MessageTestViewModel: ObservableObject {
//    private var db = CKContainer.default().privateCloudDatabase
//    @Published var messages: [Message] = []
//    
//    func addMessage(message: Message) async throws {
//        let record = try await db.save(message.record)
//        
//        guard let message = Message(record: record) else {return}
//        
//        messages.append(message)
//        
//    }
//}
//
//

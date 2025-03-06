////
////  ChatViewModel.swift
////  The Wizard of OS
////
////  Created by Dominique Karreman on 3/10/25.
////
//
//
//import SwiftUI
//import Combine
//import Foundation
//
//// Protocol om berichten door te geven van de API client naar de ViewModel
//protocol MessageUpdateProtocol: AnyObject {
//    func updateMessage(_ message: String)
//}
//
//import SwiftUI
//import Combine
//
//class ChatViewModel: ObservableObject, MessageUpdateProtocol {
//    @EnvironmentObject var messageList: MessageListModel
//    private var apiClient: StreamingAPIClient?
//
//    init() {
//        self.apiClient = StreamingAPIClient(messageDelegate: self)
//    }
//
//    func sendMessage(_ prompt: String) {
////        messageListVM.addMessage(message: prompt, sender: "You") // Add user's message
//        apiClient?.streamResponse(for: prompt) // Send request
//    }
//
//    // Protocol function for handling API responses
//    func updateMessage(_ newMessage: String) {
//        DispatchQueue.main.async {
//            self.messageList.addMessage(message: newMessage, sender: "AI") // Add AI response
//        }
//    }
//}

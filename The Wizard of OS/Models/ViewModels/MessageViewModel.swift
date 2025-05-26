//
//  MessageViewModel.swift
//  The Wizard of OS
//
//  Created by Dominique Karreman on 3/11/25.
//
import SwiftUI
import CloudKit
import Combine

import CloudKit
import SwiftUI
import UserNotifications
import CoreData

class MessageViewModel: ObservableObject {
    @Published var messages = [Message]()  // Your message model array
    static let shared = MessageViewModel()  // Singleton instance
    private let database = CKContainer.default().publicCloudDatabase
    private var subscription: CKSubscription?
    private var messageObserver: AnyCancellable?

//    init() {
//        fetchMessages()  // Fetch messages when the view model is created
//        NotificationCenter.default.addObserver(self, selector: #selector(handleLocalNotification), name: .newCloudKitData, object: nil)
//    }
//
//    @objc private func handleLocalNotification(_ notification: Notification) {
//        print("Local notification received, handling it now...")
//        fetchMessages()
//    }
//    func fetchMessagesReturn(completion: @escaping ([Message]) -> Void) {
//        let query = CKQuery(recordType: "Message", predicate: NSPredicate(value: true))
//        let sort = NSSortDescriptor(key: "timestamp", ascending: true)
//        query.sortDescriptors = [sort]
//
//        database.perform(query, inZoneWith: nil) { records, error in
//            if let error = error {
//                print("Error fetching messages: \(error.localizedDescription)")
//                completion([])  // Return an empty array in case of error
//            } else {
//                let messages = records?.compactMap { record -> Message? in
//                    // Convert recordID to UUID
//                    guard let messageText = record["message"] as? String,
//                          let sender = record["sender"] as? String,
//                          let timestamp = record["timestamp"] as? Date else {
//                              return nil  // Return nil if any required field is missing
//                          }
//
//                    let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
//                    return Message(
//                        id: id,
//                        message: messageText,
//                        sender: sender,
//                        timestamp: timestamp
//                    )
//                } ?? []  // If no records, return an empty array
//
//                DispatchQueue.main.async {
//                    self.messages = messages
//                    for message in self.messages {
//                        print("leuk spelletje: \(message.message)")
//                    }
//                    completion(messages)  // Return the messages through the completion handler
//                }
//            }
//        }
//    }
//
//
//    // Fetch messages from CloudKit
//    func fetchMessages() {
//        print("fetching these messages")
//
//        print("fetching these messages 2")
//
//            let query = CKQuery(recordType: "Message", predicate: NSPredicate(value: true))
//            let sort = NSSortDescriptor(key: "timestamp", ascending: true)
//            query.sortDescriptors = [sort]
//
//            database.perform(query, inZoneWith: nil) { [weak self] records, error in
//                if let error = error {
//                    print("Error fetching messages: \(error.localizedDescription)")
//                } else {
//                    DispatchQueue.main.async {
//                        self?.messages = records?.map { record in
//                            // Convert recordID to UUID
//                            let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
//                            return Message(
//                                id: id,  // Use UUID here
//                                message: record["message"] as? String ?? "",
//                                sender: record["sender"] as? String ?? "",
//                                timestamp: record["timestamp"] as? Date ?? Date()
//                            )
//                        } ?? []
//                    }
//                }
//            }
//        for message in self.messages {
//            print("Message: \(message.message)")
//        }
//        }
//
//
//    // Send a new message to CloudKit
//    func sendMessage(_ messageText: String) {
//        let record = CKRecord(recordType: "Message")
//
//        // Manually assign a UUID to the id field
//        let messageId = UUID()
//        record["id"] = messageId.uuidString  // Storing the UUID as a String
//        record["message"] = messageText
//        record["sender"] = "User"  // Update dynamically if needed
//        record["timestamp"] = Date()
//
//        database.save(record) { [weak self] savedRecord, error in
//            if let error = error {
//                print("Error saving message: \(error.localizedDescription)")
//            } else {
//                print("Message saved successfully with id: \(messageId)")
//                DispatchQueue.main.async {
//                    self?.fetchMessages()  // Refresh the message list after sending
//                }
//            }
//        }
//    }
//
//    // Set up CloudKit Subscription to listen for changes
//    func setupCloudKitSubscription() {
//        let subscription = CKQuerySubscription(
//            recordType: "Message",
//            predicate: NSPredicate(value: true),
//            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
//        )
//
//        // Set the notification info for the subscription
//        let notificationInfo = CKSubscription.NotificationInfo()
//        notificationInfo.alertBody = "A new message has been posted!"
//
//        notificationInfo.shouldBadge = true
//        notificationInfo.shouldSendContentAvailable = true
//        subscription.notificationInfo = notificationInfo
//
//        // Save the subscription
//        database.save(subscription) { [weak self] savedSubscription, error in
//            if let error = error {
//                print("Error setting up subscription: \(error.localizedDescription)")
//            } else {
//                self?.subscription = savedSubscription
//                print("Subscription set up successfully")
//            }
//        }
//    }
//
//    // Handle incoming notifications (e.g., when a new message is created)
//    func handleNotification(_ notification: CKNotification) {
//        print("got a noti")
//
//        // Fetch the updated messages after receiving a notification
//        self.fetchMessages()
//    }
}


class ChatMessageListViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var voiceMessages: [Message] = []
    @Published var isThinking: Bool = false
    @Published var tempAssistantMessage: tempMessage?
    @Published var tempVoiceAssistantMessage: tempMessage?
    @Published var isStreaming: Bool = false
    @State var thinkingContent: String = ""
    var streamingApiClient: StreamingAPIClient!
    
    
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        
        fetchMessages() // Fetch initial messages when the ViewModel is initialized
    }

    public func sendPrompt(_ prompt: String, image: PlatformImage?, in context: NSManagedObjectContext) {
        do {
            try self.addMessage(message: prompt, sender: "User", mode: nil, image: image ?? nil  )
            try self.isStreaming = true
            print("\(self.isStreaming): state")
            
            try streamingApiClient.streamResponse(for: prompt, image: nil, mode: .voice)
            print("✅ Streaming request sent")
            
            
        } catch {
            print("❌ Error sending prompt: \(error.localizedDescription)")
        }
    
}
    
    // Fetch messages from Core Data and update the messages array
    func fetchMessages() {
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Message.timestamp, ascending: true)]
        
        do {
            // Execute the fetch request
            let fetchedMessages = try context.fetch(fetchRequest)
            self.messages = fetchedMessages // Update the messages array with the fetched messages
        } catch {
            print("Failed to fetch messages: \(error.localizedDescription)")
        }
    }

    // Add an error message to the messages array
    func handleError(_ message: String) {
        let errorMessage = Message(message: message, sender: "Error", context: context, thinkingContent: "", clipbloardContext: "")
        self.messages.append(errorMessage)
        print("🚨 Error: \(message)") // Optional: For debugging
    }

    // Add an error message
    func addErrorMessage(_ message: String) {
        let errorMessage = Message(message: message, sender: "Error", context: context, thinkingContent: "", clipbloardContext: "")
        self.messages.append(errorMessage)
    }

    // Add a new message to the messages array (user or assistant message)
//    func addMessage(_ newMessage: String, sender: String) {
//        // Clean the message (remove prefixes and trim whitespace)
//        let cleanedMessage = newMessage
//            .replacingOccurrences(of: "data: ", with: "")
//            .replacingOccurrences(of: "\n", with: " ")
//
//        // Create a new MessageObj with the cleaned message
//        let newMessageObj = Message(
//            message: cleanedMessage,
//            sender: sender,
//            timestamp: Date(),
//            context: context
//        )
//
//        // Append the new message to the messages array
//        messages.append(newMessageObj)
//    }
    
    @AppStorage("clipboardContext") var clipboardContext: Bool = false
    @AppStorage("currentClipboard") var currentClipboard: String = ""
    
    func convertImageToData(_ image: PlatformImage) -> Data? {
        #if os(iOS)
        return image.jpegData(compressionQuality: 0.8) // or .pngData()
        #elseif os(macOS)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return nil }
        return pngData
        #endif
    }
    
    func addMessage(message: String, sender: String, mode: String?, image: PlatformImage?) {
        // Save to CoreData
        
        let newMessage = Message(context: context)
        newMessage.message = message
        newMessage.id = UUID()
        newMessage.sender = sender
        newMessage.timestamp = Date()
        if let image = image, let imageData = convertImageToData(image) {
            newMessage.imageData = imageData
        }
        
        // If clipboardContext is true, assign clipboard to the message
        if clipboardContext {
            newMessage.clipboardContext = currentClipboard
        }
        if mode == "voice" {
            self.voiceMessages.append(newMessage)
        }
        do {
            try context.save()
            fetchMessages()  // Re-fetch and update messages
        } catch {
            print("Error saving message: \(error)")
        }
    }
    
    func addTempMessage(){
        DispatchQueue.main.async {
            
            self.tempAssistantMessage = tempMessage(id: UUID(), message: "", sender: "MerlinTEMP", clipboardContext: "", timestamp: Date(), thinkingContent: "")
        }
    }
    func addVoiceTempMessage(){
        print("creating temp message")
        DispatchQueue.main.async {
            self.tempVoiceAssistantMessage = tempMessage(id: UUID(), message: "", sender: "MerlinVoiceTEMP", clipboardContext: "", timestamp: Date(), thinkingContent: "")
        }
        print(tempVoiceAssistantMessage, "tempVoiceAssistantMessage")
    }
    
    func resetTempMessage(){
        self.tempAssistantMessage = nil
        self.thinkingContent = ""
    }
    func resetTempVoiceMessage(){
        self.tempVoiceAssistantMessage = nil
        self.thinkingContent = ""
    }

    // Add a new assistant message (empty message to be updated later)
    func addAssistantMessage() {
        let assistantMessage = Message(
            message: "", // Initialize with an empty message
            sender: "Merlin", // Set the sender to "Assistant"
            context: context, thinkingContent: "", clipbloardContext: ""
        )
        
        // Append the new assistant message to the messages array
        messages.append(assistantMessage)
    }

    // Add a user message and trigger the thinking state
    @MainActor func addUserMessage(message: String) {
        
        isThinking = true
        let userMessage = Message(
            message: message, // Initialize with the user message
            sender: "User", // Set the sender to "User"
            context: context, thinkingContent: "", clipbloardContext: ""
        )
        
        // Append the new user message to the messages array
        messages.append(userMessage)
        
        // Save to Core Data
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }

    // Update the last message with new chunks of text (used to append assistant's response)
    func updateChunks(_ chunk: String) {
       
        // Ensure there is a last message to update
        guard let lastMessageIndex = messages.indices.last else {
            return
        }
        
        // Clean the incoming chunk of text
        let cleanedChunk = chunk
            .replacingOccurrences(of: "data: ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "__NEWLINE__", with: "\n")
        
        // Safely unwrap the last message's 'message' and append the cleaned chunk
        if var lastMessage = messages[lastMessageIndex].message {
            // Append the cleaned chunk to the last message
            lastMessage += cleanedChunk
            // Update the message back to the array
            messages[lastMessageIndex].message = lastMessage
        } else {
            // If message was nil, initialize it with the cleaned chunk
            messages[lastMessageIndex].message = cleanedChunk
        }
        
        // Optionally save the changes to Core Data here if necessary:
        do {
            try context.save()
        } catch {
            print("Error saving chunked message: \(error.localizedDescription)")
        }
    }
}


class ChatMessageViewModel: ObservableObject {
    @Published var message: String = "test"
    
    
    func addMessage(_ newMessage: String) {
        // Remove "data: " prefix if present and trim whitespace
        let cleanedMessage = newMessage
            .replacingOccurrences(of: "data: ", with: "")
        // Remove double newlines
            .replacingOccurrences(of: "\n", with: " ")  /*Replace single newlines with a space*/
        
        
        // Append the cleaned message with a space to maintain paragraph formatting
        message.append("\(cleanedMessage)")
    }
    
    
}

//import SwiftUI
//import Foundation
//import Combine
//
//#if os(iOS)
//import UIKit
//typealias PlatformImage = UIImage
//#elseif os(macOS)
//import AppKit
//typealias PlatformImage = NSImage
//#endif
//
//class StreamingAPIClient: NSObject, URLSessionDataDelegate {
//    private var cancellables = Set<AnyCancellable>()
//    private var dataTask: URLSessionDataTask?
//    weak var chatMessageVM: ChatMessageViewModel? // Use a weak reference to avoid strong reference cycles
//    weak var chatMessageListVM: ChatMessageListViewModel?
//    
//    
//     
//    init(chatMessageVM: ChatMessageViewModel, chatMessageListVM: ChatMessageListViewModel) {
//        self.chatMessageVM = chatMessageVM
//        self.chatMessageListVM = chatMessageListVM // Initialize messageListVM
//        super.init() // Call to super.init() must come first
//    }
//    
////    func retrieveAvatarToken() -> String? {
////        let query: [String: Any] = [
////            kSecClass as String: kSecClassGenericPassword,
////            kSecAttrAccount as String: "avatar_token",
////            kSecReturnData as String: kCFBooleanTrue!,
////            kSecMatchLimit as String: kSecMatchLimitOne
////        ]
////        
////        var item: CFTypeRef?
////        let status = SecItemCopyMatching(query as CFDictionary, &item)
////        
////        if status == errSecSuccess, let tokenData = item as? Data {
////            return String(data: tokenData, encoding: .utf8)
////        }
////        
////        return nil
////    }
//
//    func streamResponse(for prompt: String, image: PlatformImage?) {
//        print("test")
//        guard let url = URL(string: "https://3010-145-44-53-109.ngrok-free.app/prompt/text") else { return }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//
//        if let image = image {
//            let boundary = UUID().uuidString
//            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//            
//            // Create the HTTP body with prompt and image
//            var body = Data()
//            body.append("--\(boundary)\r\n".data(using: .utf8)!)
//            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
//            body.append("\(prompt)\r\n".data(using: .utf8)!)
//            
//            // Convert NSImage to JPEG data
//            if let imageData = imageToJPEGData(image) {
//                body.append("--\(boundary)\r\n".data(using: .utf8)!)
//                body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
//                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
//                body.append(imageData)
//                body.append("\r\n".data(using: .utf8)!)
//            }
//            
//            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
//            request.httpBody = body
//        } else {
//            // Send the prompt as JSON if no image is provided
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            let recall = UserDefaults.standard.bool(forKey: "recall")
//            let json: [String: Any] = ["prompt": prompt, "recall": recall]
//            let jsonData = try? JSONSerialization.data(withJSONObject: json)
//            request.httpBody = jsonData
//            print(json, "json")
//        }
//
//        let config = URLSessionConfiguration.default
//        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
//
//        dataTask = session.dataTask(with: request)
//        dataTask?.resume()
//    }
//
//    func imageToJPEGData(_ image: NSImage) -> Data? {
//        guard let tiffData = image.tiffRepresentation else { return nil }
//        
//        let bitmapRep = NSBitmapImageRep(data: tiffData)
//        let jpegData = bitmapRep?.representation(using: .jpeg, properties: [:])
//        
//        return jpegData
//    }
//    
//    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
////        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
//        
//        // Ensure the assistant message is created only once before updating chunks
//        DispatchQueue.main.async {
//            if self.chatMessageListVM?.messages.last?.sender != "Merlin" {
//                self.chatMessageListVM?.addAssistantMessage()
//                // self.chatMessageListVM?.isThinking = false // Uncomment if needed
//            }
//        }
//        
//        // Handle the streaming data
//        if let streamData = String(data: data, encoding: .utf8) {
//            DispatchQueue.main.async {
//                // Append the streaming chunk to the assistant's message
//                self.chatMessageListVM?.updateChunks(streamData)
//                
////                impactFeedback.impactOccurred()
//            }
//        }
//    }
//}

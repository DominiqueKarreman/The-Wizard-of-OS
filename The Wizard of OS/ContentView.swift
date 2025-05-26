//
//  ContentView.swift
//  The Wizard of OS
//
//  Created by Dominique Karreman on 3/6/25.
//

import SwiftUI
import SwiftData
import Combine
import CoreData
import Network

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
import CoreData
typealias PlatformImage = NSImage
#endif

class StreamingAPIClient: NSObject, URLSessionDataDelegate {
    private var dataTask: URLSessionDataTask?
    var voiceStatus: ListeningState?
    weak var chatMessageVM: ChatMessageViewModel?
    weak var chatMessageListVM: ChatMessageListViewModel?
    private let context: NSManagedObjectContext
    @AppStorage("offline") private var offline: Bool = false

    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init(chatMessageVM: ChatMessageViewModel, chatMessageListVM: ChatMessageListViewModel, context: NSManagedObjectContext) {
        self.chatMessageVM = chatMessageVM
        self.chatMessageListVM = chatMessageListVM
        self.context = context
        super.init()

        // Start monitoring network status
        
    }
    enum StreamResponseError: Error {
        case invalidURL
        case jsonEncodingFailed(Error)
        case streamError(String)
    }
    public enum Modes: String {
        case text
        case voice
    }
    public var currentMode: Modes = .text
    
    func streamResponse(for prompt: String, image: PlatformImage?, mode: Modes = .text) {
        print("mode is \(mode)")
        self.currentMode = mode
        
        print("in streamResponse for \(self.currentMode)")
        let baseURL = offline ? "http://localhost:11434/api/generate" : "\(APIConstants.baseURL)/prompt/text"
        guard let url = URL(string: baseURL) else {
            self.handleError(.invalidURL)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if offline {
            // 🟢 Ollama Local Mode: Always JSON request with streaming
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let model = UserDefaults.standard.string(forKey: "model") ?? "llama3"
            let json: [String: Any] = ["model": model, "prompt": prompt, "stream": true]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: json)
            } catch {
                self.handleError(.jsonEncodingFailed(error))
                return
            }
        } else {
            // 🌐 Online Mode: Supports JSON or multipart for images
            if let image = image {
                let boundary = UUID().uuidString
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

                var body = Data()
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(prompt)\r\n".data(using: .utf8)!)

                if let imageData = imageToJPEGData(image) {
                    body.append("--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
                    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                    body.append(imageData)
                    body.append("\r\n".data(using: .utf8)!)
                }

                body.append("--\(boundary)--\r\n".data(using: .utf8)!)
                request.httpBody = body
            } else {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let recall = UserDefaults.standard.bool(forKey: "recall")
                let model = UserDefaults.standard.string(forKey: "model") ?? "default_model"
                let clipboardContext = UserDefaults.standard.bool(forKey: "clipboardContext") // Directly read from UserDefaults
                var clipboard = UserDefaults.standard.string(forKey: "currentClipboard") ?? ""
                
                let json: [String: Any] = ["prompt": prompt, "recall": recall, "model": model, "clipboard": clipboard, "clipboardContext": clipboardContext]

                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: json)
                } catch {
                    self.handleError(.jsonEncodingFailed(error))
                    return
                }
            }
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        dataTask = session.dataTask(with: request)
        dataTask?.resume()
        DispatchQueue.main.async {
            
            
            if mode == .text {
                print("in streamResponse for text: \(self.currentMode)")
                self.chatMessageListVM?.addTempMessage()
            }
            if mode == .voice {
                self.chatMessageListVM?.addVoiceTempMessage()
            }
        }
    }

    @MainActor func updateChunks(_ chunk: String) {

        guard let chatMessageListVM = chatMessageListVM else { return }
        if offline {
            // 🟢 Ollama JSON Parsing
            if let jsonData = chunk.data(using: .utf8),
               let responseDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let responseText = responseDict["response"] as? String {
                
                DispatchQueue.main.async {
                    if self.currentMode == .text {
                        chatMessageListVM.tempVoiceAssistantMessage?.message += responseText
                       
                    }
                    
                    if self.currentMode == .voice {
                        print("contents: \(chatMessageListVM.tempVoiceAssistantMessage?.message ?? "")")
                        chatMessageListVM.tempVoiceAssistantMessage?.message += responseText
                    }
                    
                }

            }
        } else {
            // 🌐 Online Mode: Direct Text Processing
            let cleanedChunk = chunk
                .replacingOccurrences(of: "data: ", with: "")
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "__NEWLINE__", with: "\n")
            
            print("updating chunks: \(self.currentMode)")
            DispatchQueue.main.async {
                if self.currentMode == .text {
                    chatMessageListVM.tempAssistantMessage?.message += cleanedChunk
                }
                if self.currentMode == .voice {
                    print("contents: \(chatMessageListVM.tempAssistantMessage?.message ?? "")")
                    chatMessageListVM.tempVoiceAssistantMessage?.message += cleanedChunk
                }
              
            }

            // 🏁 If the chunk is the final part of the response, finalize message
      
        }
    }

    @MainActor private func finalizeStreamingMessage() {
        print("in finalize for \(self.currentMode)")
        if currentMode == .text {
            context.perform {
                do {
                    guard let chatMessageListVM = self.chatMessageListVM,
                          let tempMessage = chatMessageListVM.tempAssistantMessage else { return }
                    
                    print("📝 Finalizing streamed message: \(tempMessage.message)")
                    self.chatMessageListVM?.isStreaming = false
                    // 🟢 Create final message object
                    let saveMessageAssistant = Message(context: self.context)
                    saveMessageAssistant.id = UUID()
                    saveMessageAssistant.sender = "Merlin"
                    saveMessageAssistant.timestamp = Date()
                    saveMessageAssistant.message = tempMessage.message
                    
                    if let content = self.chatMessageListVM?.tempAssistantMessage?.thinkingContent {
                        saveMessageAssistant.thinkingContent = content
                    } else {
                        saveMessageAssistant.thinkingContent = nil
                    }
                    try self.context.save()
                    
                    // ✅ Move temp message to permanent list and reset
                    self.chatMessageListVM?.resetTempMessage()
                    
                    print("✅ Assistant message saved successfully.")
                } catch {
                    print("❌ Failed to save final assistant message: \(error.localizedDescription)")
                }
            }
        } else {
            guard let chatMessageListVM = self.chatMessageListVM,
                  let tempMessage = chatMessageListVM.tempVoiceAssistantMessage else { return }
           
            let voiceMessage = Message(context: self.context)
            voiceMessage.id = UUID()
            voiceMessage.sender = "Merlin"
            voiceMessage.timestamp = Date()
            voiceMessage.message = tempMessage.message
            DispatchQueue.main.async {
                self.chatMessageListVM?.isStreaming = false
                self.chatMessageListVM?.resetTempVoiceMessage()
                chatMessageListVM.resetTempVoiceMessage()
                self.chatMessageListVM?.voiceMessages.append(voiceMessage)
            }
     
            voiceStatus = .idle
            print(voiceStatus, " state")
            
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
      
        if let streamData = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                print("print \(streamData)")
                self.updateChunks(streamData)
            }
        } else {
            self.handleError(.streamError("Failed to parse stream data"))
        }
    }

    @MainActor func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.handleError(.streamError(error.localizedDescription))
        }
        
        finalizeStreamingMessage()
    }

    private func handleError(_ error: StreamResponseError) {
        DispatchQueue.main.async {
            switch error {
            case .invalidURL:
                self.chatMessageListVM?.addErrorMessage("Invalid URL. Check the server endpoint.")
            case .jsonEncodingFailed(let encodingError):
                self.chatMessageListVM?.addErrorMessage("JSON encoding failed: \(encodingError.localizedDescription)")
            case .streamError(let message):
                self.chatMessageListVM?.addErrorMessage("Stream error: \(message)")
            }
        }
    }

    func imageToJPEGData(_ image: PlatformImage) -> Data? {
        #if os(iOS)
        return image.jpegData(compressionQuality: 1.0)
        #elseif os(macOS)
        guard let tiffData = image.tiffRepresentation else { return nil }
        let bitmapRep = NSBitmapImageRep(data: tiffData)
        return bitmapRep?.representation(using: .jpeg, properties: [:])
        #endif
    }
}

public struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var chatMessageVM = ChatMessageViewModel()
    @AppStorage("voiceModeActive") var voiceModeActive: Bool = false
    @AppStorage("videoModeActive") var videoModeActive: Bool = false
    
    @AppStorage("screenshotModeActive") var screenshotModeActive: Bool = false
    
    @State var prompt: String = ""
    @State private var selectedImage: PlatformImage? = nil
    var streamingApiClient: StreamingAPIClient!
    let persistenceController = PersistenceController.shared
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Message.timestamp, ascending: true)],
        animation: .default
    ) private var messages: FetchedResults<Message>
    
    @ObservedObject var messageListVM: ChatMessageListViewModel
    
    // Custom initializer
    init() {
        _messageListVM = ObservedObject(wrappedValue: ChatMessageListViewModel(context: PersistenceController.shared.container.viewContext )) // Initialize messageListVM with context
        streamingApiClient = StreamingAPIClient(chatMessageVM: chatMessageVM, chatMessageListVM: _messageListVM.wrappedValue, context: PersistenceController.shared.container.viewContext) // Initialize the API client
        messageListVM.streamingApiClient = self.streamingApiClient
    }

    public var body: some View {
        GeometryReader { geometry in
            VStack {
                #if os(macOS)
                // Optional: Image Picker Button
            
                if messages.isEmpty {
                    Spacer()
                    ChatStreamTextEffect(text: "Ik ben MERLIN hoe kan ik je helpen vandaag?", fontSize: 32, startDelay: 1, delayPerChunk: 0.03)
                    PromptTF(selectedImage: $selectedImage, streamingApiClient: streamingApiClient, messageListVM: messageListVM, title: "Prompt:", text: $prompt, voiceModeActive: $voiceModeActive, videoModeActive: $videoModeActive, screenshotModeActive: $screenshotModeActive).padding(30)
                    Spacer()
                } else {
                    if voiceModeActive {
                        SpeechView(context: viewContext, messageListVM: messageListVM, streamingApiClient: StreamingAPIClient(chatMessageVM: ChatMessageViewModel(), chatMessageListVM: messageListVM, context: viewContext)).environmentObject(messageListVM)
                    } else {
                        MessageListView(messageListVM: messageListVM, messages: messages).zIndex(-1)
                            .padding(40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))  // This will make it slide from the bottom
                            .animation(.easeInOut(duration: 0.5), value: voiceModeActive) // Add a smooth animation effect
                            .environment(\.managedObjectContext, persistenceController.container.viewContext)

                    }
                    Spacer()
                    PromptTF(selectedImage: $selectedImage, streamingApiClient: streamingApiClient, messageListVM: messageListVM, title: "Prompt:", text: $prompt, voiceModeActive: $voiceModeActive, videoModeActive: $videoModeActive, screenshotModeActive: $screenshotModeActive).padding(30).environmentObject(messageListVM)
                }
                #elseif os(iOS)
                if messages.isEmpty {
                    Spacer()
                    ChatStreamTextEffect(text: "Ik ben MERLIN, hoe kan ik je helpen vandaag?", fontSize: 28, startDelay: 1, delayPerChunk: 0.03)
                    PromptTF(selectedImage: $selectedImage, streamingApiClient: streamingApiClient, messageListVM: messageListVM, title: "Prompt:", text: $prompt, voiceModeActive: $voiceModeActive, videoModeActive: $videoModeActive, screenshotModeActive: $screenshotModeActive).padding(30)
                    Spacer()
                } else {
                    
                    if voiceModeActive {
                    } else {
                        MessageListView(messageListVM: messageListVM, messages: messages).zIndex(-1)
                            .padding(40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))  // This will make it slide from the bottom
                            .animation(.easeInOut(duration: 0.5), value: voiceModeActive) // Add a smooth animation effect
                            .environment(\.managedObjectContext, persistenceController.container.viewContext)

                    }
                    
                    Spacer()
                    PromptTF(selectedImage: $selectedImage, streamingApiClient: streamingApiClient, messageListVM: messageListVM, title: "Prompt:", text: $prompt, voiceModeActive: $voiceModeActive, videoModeActive: $videoModeActive, screenshotModeActive: $screenshotModeActive).padding(10)
                }
                #endif
            }
            .frame(width: geometry.size.width, height: geometry.size.height) // Automatically adjusts height
            
            .background(
                ZStack {
                        Image("MagicPattern") // Replace with your image name
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width + 50, height: geometry.size.height + 250)
                            .clipped()
                        
                        // Apply a dark overlay only to the background
                        Color.black.opacity(colorScheme == .dark ? 0.5 : 0.0)
                    }
            )
        }
    }
}


#if canImport(SwiftUI)
// Model selection view (Modal content)
struct ModelSelectionView: View {
    
    @AppStorage("model") private var selectedModel: String = "llama3"
    let models = ["llama3", "deepseek-r1"] // List of available models
    @Binding var isModalPresented: Bool
    
    var body: some View {
        ZStack {
            if isModalPresented {
                VStack {
                    // Background overlay
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture { isModalPresented.toggle() }
                        .accessibilityIdentifier("ModelSelectionModalBackground")

                    VStack {
                        Text("Select a Model")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding()

                        ScrollView {
                            VStack {
                                ForEach(models, id: \.self) { model in
                                    HStack {
                                        Text(model)
                                            .font(.body)
                                            .padding()
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            selectedModel = model // Update selected model
                                            isModalPresented.toggle() // Close the modal
                                        }) {
                                            Text("Select")
                                                .padding()
                                                
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        .accessibilityIdentifier("SelectModelButton_\(model)") // Add unique identifier for each button
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // Optional: Close button at the bottom of the modal
                        Button("Close") {
                            isModalPresented.toggle()
                        }
                        .padding()
                    }
                    .frame(width: 400, height: 400)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
            }
        }
    }
}
#endif
#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}



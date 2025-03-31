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

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
import CoreData
typealias PlatformImage = NSImage
#endif

class StreamingAPIClient: NSObject, URLSessionDataDelegate {
    private var cancellables = Set<AnyCancellable>()
    private var dataTask: URLSessionDataTask?
    weak var chatMessageVM: ChatMessageViewModel?
    weak var chatMessageListVM: ChatMessageListViewModel?
    private let context: NSManagedObjectContext // Inject Core Data context

    init(chatMessageVM: ChatMessageViewModel, chatMessageListVM: ChatMessageListViewModel,context: NSManagedObjectContext) {
        self.chatMessageVM = chatMessageVM
        self.chatMessageListVM = chatMessageListVM
        self.context = context
        super.init()
    }

    enum StreamResponseError: Error {
        case invalidURL
        case jsonEncodingFailed(Error)
        case ngrokTunnelFailure(String)
        case streamError(String)
    }

    // Main streaming function
    func streamResponse(for prompt: String, image: PlatformImage?) {
        // URL validation
        guard let url = URL(string: "\(APIConstants.baseURL)/prompt/text") else {
            self.handleError(.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Handle image or plain prompt
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
            // If no image, send the prompt in JSON format
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let recall = UserDefaults.standard.bool(forKey: "recall")
            let model = UserDefaults.standard.string(forKey: "model")
            let json: [String: Any] = ["prompt": prompt, "recall": recall, "model": model]

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: json)
                request.httpBody = jsonData
            } catch {
                self.handleError(.jsonEncodingFailed(error))
                return
            }
        }
      
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        dataTask = session.dataTask(with: request)
        dataTask?.resume()
        chatMessageListVM?.addTempMessage()
    }

    // Convert UIImage (iOS) or NSImage (macOS) to JPEG data
    func imageToJPEGData(_ image: PlatformImage) -> Data? {
        #if os(iOS)
        return image.jpegData(compressionQuality: 1.0)
        #elseif os(macOS)
        guard let tiffData = image.tiffRepresentation else { return nil }
        
        let bitmapRep = NSBitmapImageRep(data: tiffData)
        let jpegData = bitmapRep?.representation(using: .jpeg, properties: [:])
        
        return jpegData
        #endif
    }

    // Error handler function
    private func handleError(_ error: StreamResponseError) {
        DispatchQueue.main.async {
            switch error {
            case .invalidURL:
                print("❌ Invalid URL error")
                self.chatMessageListVM?.addErrorMessage("Invalid URL. Please check the server endpoint.")
            case .jsonEncodingFailed(let encodingError):
                print("❌ JSON encoding failed: \(encodingError.localizedDescription)")
                self.chatMessageListVM?.addErrorMessage("Failed to encode JSON. Please try again.")
            case .ngrokTunnelFailure(let message):
                print("❌ Ngrok tunnel failure: \(message)")
                self.chatMessageListVM?.addErrorMessage("Ngrok tunnel failure. Please check the connection.")
            case .streamError(let message):
                print("❌ Stream error: \(message)")
                self.chatMessageListVM?.addErrorMessage("Stream error: \(message)")
            }
        }
    }
    func updateChunks(_ chunk: String) {
        guard let chatMessageListVM = chatMessageListVM else { return }

        let cleanedChunk = chunk
            .replacingOccurrences(of: "data: ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "__NEWLINE__", with: "\n")

        // Ensure UI updates happen on the main thread
        DispatchQueue.main.async {
            chatMessageListVM.tempAssistantMessage?.message += cleanedChunk
            print("📥 Updating temporary message: \(cleanedChunk)")
        }
    }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
          
            if let streamData = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.updateChunks(streamData)
                }
                print("Received streaming chunk: \(streamData)")
            } else {
                self.handleError(.streamError("Failed to parse stream data"))
            }
        }
    @MainActor func saveLastMerlinMessage() {
        // Find the last message with sender "Merlin"
        if let lastMerlinMessage = chatMessageListVM?.messages.last(where: { $0.sender == "Merlin" }) {
            // Save or process the last "Merlin" message
            // You can save it to a database, or just append it to another list, depending on your needs.
            print("Last Merlin message found: \(lastMerlinMessage.message)")
            lastMerlinMessage.saveMessage()
            
            // Example: Save it to another array or perform any desired action
            // chatMessageListVM?.saveMessage(lastMerlinMessage)  // Custom method to save message
        } else {
            print("No message from Merlin found.")
        }
    }
    // URLSession delegate to handle errors
    @MainActor func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ URLSession Task failed with error: \(error.localizedDescription)")
            self.handleError(.streamError(error.localizedDescription))
        } else {
            context.perform {
                do {
                    // 🟢 Save the assistant message after streaming completes
                    self.chatMessageListVM?.isStreaming = false
                    var saveMessageAssistant = Message(context: self.context)
                    saveMessageAssistant.id = UUID()
                    saveMessageAssistant.sender = "Merlin"
                    saveMessageAssistant.timestamp = Date()
                    saveMessageAssistant.message = self.chatMessageListVM?.tempAssistantMessage?.message
                    if let content = self.chatMessageListVM?.tempAssistantMessage?.thinkingContent {
                        saveMessageAssistant.thinkingContent = content
                    } else {
                        saveMessageAssistant.thinkingContent = nil
                    }
                    print("ZOu het aan mij liggen: \(saveMessageAssistant.thinkingContent)")
                    
                    try self.context.save()
                    
                    self.chatMessageListVM?.resetTempMessage()
                    
                    print("✅ Assistant message saved after stream completion state: \(self.chatMessageListVM?.isStreaming)")
                } catch {
                    print("❌ Failed to save final assistant message: \(error.localizedDescription)")
                }
            }
        }
    }
}

public struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var chatMessageVM = ChatMessageViewModel()
    
    @State var prompt: String = ""
    var streamingApiClient: StreamingAPIClient!
    let persistenceController = PersistenceController.shared
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Message.timestamp, ascending: true)],
        animation: .default
    ) private var messages: FetchedResults<Message>
    
    @ObservedObject var messageListVM: ChatMessageListViewModel
    
    // Custom initializer
    init() {
        _messageListVM = ObservedObject(wrappedValue: ChatMessageListViewModel(context: PersistenceController.shared.container.viewContext)) // Initialize messageListVM with context
        streamingApiClient = StreamingAPIClient(chatMessageVM: chatMessageVM, chatMessageListVM: _messageListVM.wrappedValue, context: PersistenceController.shared.container.viewContext) // Initialize the API client
    }

    public var body: some View {
        GeometryReader { geometry in
            VStack {
                #if os(macOS)
                if messages.isEmpty {
                    Spacer()
                    ChatStreamTextEffect(text: "Ik ben MERLIN hoe kan ik je helpen vandaag?", fontSize: 32, startDelay: 1, delayPerChunk: 0.03)
                    PromptTF(streamingApiClient: streamingApiClient, messageListVM: messageListVM, title: "Prompt:", text: $prompt).padding(30)
                    Spacer()
                } else {
                    MessageListView(messageListVM: messageListVM, messages: messages).padding(40).environment(\.managedObjectContext, persistenceController.container.viewContext)
                    Spacer()
                    PromptTF(streamingApiClient: streamingApiClient, messageListVM: messageListVM, title: "Prompt:", text: $prompt).padding(30).environmentObject(messageListVM)
                }
                #elseif os(iOS)
                if messages.isEmpty {
                    Spacer()
                    ChatStreamTextEffect(text: "Ik ben MERLIN, hoe kan ik je helpen vandaag?", fontSize: 28, startDelay: 1, delayPerChunk: 0.03)
                    PromptTF(streamingApiClient: streamingApiClient, messageListVM: messageListVM, title: "Prompt:", text: $prompt).padding(30)
                    Spacer()
                } else {
                    MessageListView(messageListVM: messageListVM, messages: messages).padding(40).environment(\.managedObjectContext, persistenceController.container.viewContext)
                    Spacer()
                    PromptTF(streamingApiClient: streamingApiClient, messageListVM: messageListVM, title: "Prompt:", text: $prompt).padding(30)
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
struct PromptTF: View {
    
    var streamingApiClient: StreamingAPIClient!
    @ObservedObject var messageListVM: ChatMessageListViewModel
    var title: String // Title for the text field
    @Binding var text: String // Binding for the text input
    @FocusState var isActive // State to manage focus on the text field
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showModelSelectionModal = false // State to trigger the modal
    @State private var selectedModel: String? = nil // Track selected model
    
    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                // Background rectangle with opacity
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("TextField").opacity(0.5))
                    .frame(height: 55)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.8), lineWidth: 1) // Light stroke for the border
                            .blur(radius: 4) // Blur to create the inner shadow effect
                            .padding(4) // Padding to make the inner shadow look inset
                            .blendMode(.overlay) // To enhance shadow effect
                    )
                
                HStack {
                    TextField("", text: $text)
                        .textFieldStyle(.plain) // Remove default style
                        .background(.clear) // Ensure no extra background
                        .frame(maxWidth: .infinity, maxHeight: 55).accessibilityIdentifier("textFieldInput")
                        .padding(.horizontal, 12)
                        .focused($isActive)
                        .onSubmit { // Trigger action when Enter is pressed
                            if text != "" {
                                sendPrompt(text, in: viewContext)
                                text = ""
                            }
                        }
                    
                    Button(action: {
                        if text != "" {
                            sendPrompt(text, in: viewContext)
                            text = ""
                        }
                    }) {
                        Image(systemName: "paperplane.fill") // Use SF Symbol
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20) // Adjust size
                            .foregroundColor(.white)
                            .padding(.trailing, 20) // Set icon color
                    }
                    .buttonStyle(.plain) // Removes default button styling
                    .background(.clear) // Ensures no background
                }
            }
            .padding(.horizontal)
            
            // Add a group of pill-shaped buttons underneath the text field
            HStack(spacing: 15) {
                Button(action: {
                    // Trigger the modal to show
                    showModelSelectionModal = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "brain") // Icon
                            .font(.system(size: 13))
                            
                        Text("model") // Label
                            .font(.subheadline)
                            
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color("TextField")) // Background color of the pill button
                    .cornerRadius(6) // Pill shape
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showModelSelectionModal) {
                    // Modal content for selecting a model
                    ModelSelectionView(isModalPresented: $showModelSelectionModal)
                }
                
//                Button(action: {
//                    print("Button 2 pressed")
//                }) {
//                    HStack(spacing: 10) {
//                        Image(systemName: "heart.fill") // Icon
//                            .font(.system(size: 18))
//                            .foregroundColor(.red)
//                        Text("Option 2") // Label
//                            .font(.caption)
//                            .foregroundColor(.red)
//                    }
//                    .padding(.vertical, 8)
//                    .padding(.horizontal, 16)
//                    .background(Color("TextField")) // Background color of the pill button
//                    .foregroundColor(.red) // Text and icon color
//                    .cornerRadius(6) // Pill shape
//                }
//                .buttonStyle(PlainButtonStyle())
//                
//                Button(action: {
//                    print("Button 3 pressed")
//                }) {
//                    HStack(spacing: 10) {
//                        Image(systemName: "bell.fill") // Icon
//                            .font(.system(size: 18))
//                            .foregroundColor(.green)
//                        Text("Option 3") // Label
//                            .font(.caption)
//                            .foregroundColor(.green)
//                    }
//                    .padding(.vertical, 8)
//                    .padding(.horizontal, 16)
//                    .background(Color("TextField")) // Background color of the pill button
//                    .foregroundColor(.green) // Text and icon color
//                    .cornerRadius(6) // Pill shape
//                }
//                .buttonStyle(PlainButtonStyle())
                Spacer()
            } .padding(.horizontal)
            .padding(.top, 5) // Space between the prompt bar and buttons
            .frame(maxWidth: .infinity, alignment: .center) // Make the buttons centered
        }
    }
    
    // Function to send message
    func sendPrompt(_ prompt: String, in context: NSManagedObjectContext) {
        do {
            try messageListVM.addMessage(message: prompt, sender: "User")
            try messageListVM.isStreaming = true
            print("\(messageListVM.isStreaming): state")
            
            try streamingApiClient.streamResponse(for: prompt, image: nil) // Start the streaming response
            print("✅ Streaming request sent")
            
        } catch {
            print("❌ Error sending prompt: \(error.localizedDescription)")
        }
    }
}

// Model selection view (Modal content)
struct ModelSelectionView: View {
    
    @AppStorage("model") private var selectedModel: String = "llama3"
    let models = ["llama3", "deepseek"] // Example models list
    @Binding var isModalPresented: Bool // To control modal visibility
    
    var body: some View {
        ZStack {
            // Main Content
            VStack {
                Button("Select Model") {
                    isModalPresented.toggle() // Show the modal
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .frame(width: 200)
                
                Spacer()
            }
            
            // Modal View
            if isModalPresented {
                VStack {
                    // Modal Background
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            isModalPresented.toggle() // Dismiss the modal on background tap
                        }
                    
                    // Modal Content
                    VStack {
                        Text("Select a Model")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding()
                            .foregroundColor(.blue)
                        
                        Picker("Choose Model", selection: $selectedModel) {
                            ForEach(models, id: \.self) { model in
                                Text(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedModel) { newValue in
                            // Model selection is automatically handled by @AppStorage
                            
                            print("Selected model: \(newValue)")
                        } // Fixed height for List
                        
                        // Done Button
                        
                    }
                    .frame(width: 400, height: 300) // Set a fixed size for the modal
                    
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
                .transition(.move(edge: .bottom)) // Smooth modal transition
                .animation(.easeInOut, value: isModalPresented) // Animate modal appearance/disappearance
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

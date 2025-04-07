
struct PromptTF: View {
    
    @StateObject private var networkMonitor = NetworkMonitor()
    
    var streamingApiClient: StreamingAPIClient!
    @ObservedObject var messageListVM: ChatMessageListViewModel
    var title: String
    @Binding var text: String
    @FocusState var isActive
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showModelSelectionModal = false
    @State private var isHovered = false
    @State private var isHoveredOfflineButton = false // New hover state for the Offline button
    @AppStorage("model") private var selectedModel: String = "llama3"
    
    @AppStorage("offline") private var offline: Bool = false
    

    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("TextField").opacity(0.5))
                    .frame(height: 55)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.8), lineWidth: 1)
                            .blur(radius: 4)
                            .padding(4)
                            .blendMode(.overlay)
                    )
                
                HStack {
                    TextField("", text: $text).accessibilityIdentifier("textFieldInput")
                        .textFieldStyle(.plain)
                        .background(.clear)
                        .frame(maxWidth: .infinity, maxHeight: 55)
                        .padding(.horizontal, 12)
                        .focused($isActive)
                        .onSubmit {
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
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                            .padding(.trailing, 20)
                    }
                    .buttonStyle(.plain)
                    .background(.clear)
                }
            }
            .padding(.horizontal)
            
            // Buttons underneath the text field
            HStack(spacing: 15) {
                Button(action: {
                    showModelSelectionModal = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "brain")
                            .font(.system(size: 13))
                            
                        Text(selectedModel) // Display selected model
                            .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color("TextField").opacity(isHovered ? 0.6 : 0.3)) // Darken on hover
                    .cornerRadius(6)
                }.accessibilityIdentifier("ModelSelectionButton")
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    isHovered = hovering
                }
                .overlay( // Overlay ensures the popup does NOT affect layout
                    Group {
                        if isHovered {
                            Text("Select model")
                                .font(.caption)
                                .padding(12)
                                .background(Color("TextField"))
                                .cornerRadius(6)
                                .shadow(radius: 5)
                                .offset(y: -45) // Position above the button
                        }
                    }
                )
                .sheet(isPresented: $showModelSelectionModal) {
                    ModelSelectionView(isModalPresented: $showModelSelectionModal)
                }

                // Second button (Offline)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) { // Animate state change
                        offline.toggle()
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: offline ? "wifi.slash" : "wifi")
                            .font(.system(size: 13))
                            .foregroundColor(offline ? .red : .green) // Color changes dynamically
                            .transition(.scale.combined(with: .opacity)) // Smooth effect
                        
                        Text(offline ? "Offline" : "Online")   .accessibilityIdentifier("OfflineOnlineText")
                            .font(.subheadline)
                            .foregroundColor(offline ? .red.opacity(0.8) : .green.opacity(0.8)) // Adjust text color
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        offline
                        ? Color("TextField").opacity(0.9)  // Darker when active
                        : Color("TextField").opacity(isHoveredOfflineButton ? 0.5 : 0.3) // Lighter when inactive
                    )
                    .cornerRadius(6)
                    .scaleEffect(offline ? 0.95 : 1) // Slight shrink when pressed
                    .animation(.easeInOut(duration: 0.2), value: offline) // Smooth transition
                }
                .disabled(!networkMonitor.isConnected) // 🔹 Disable when offline there's no internet
                .accessibilityIdentifier("OfflineButton") // Assign identifier to the button itself
                .accessibilityElement(children: .combine)
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    isHoveredOfflineButton = hovering
                }
                .overlay( // Overlay ensures the popup does NOT affect layout
                    Group {
                        if isHoveredOfflineButton { // Show a different hover message for the Offline button
                            Text("Offline mode")
                                .font(.caption)
                                .padding(12)
                                .background(Color("TextField"))
                                .cornerRadius(6)
                                .shadow(radius: 5)
                                .offset(y: -45) // Position above the button
                        }
                    }
                )
                .sheet(isPresented: $showModelSelectionModal) {
                    ModelSelectionView(isModalPresented: $showModelSelectionModal)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 5)
            .frame(maxWidth: .infinity, alignment: .leading) // Keep everything aligned
        }
    }
    
    // Function to send message
    func sendPrompt(_ prompt: String, in context: NSManagedObjectContext) {
        do {
            try messageListVM.addMessage(message: prompt, sender: "User")
            try messageListVM.isStreaming = true
            print("\(messageListVM.isStreaming): state")
            
            try streamingApiClient.streamResponse(for: prompt, image: nil)
            print("✅ Streaming request sent")
            
        } catch {
            print("❌ Error sending prompt: \(error.localizedDescription)")
        }
    }
}

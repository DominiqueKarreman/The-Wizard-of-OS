import SwiftUI
import Network
import Combine
import CoreData

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PromptTF: View {
    
    @StateObject private var networkMonitor = NetworkMonitor()
    @Binding var selectedImage: PlatformImage?
    var streamingApiClient: StreamingAPIClient!
    @ObservedObject var messageListVM: ChatMessageListViewModel
    var title: String
    @Binding var text: String
    @FocusState var isActive
    @Binding var voiceModeActive: Bool
    @Binding var videoModeActive: Bool
    @Binding var screenshotModeActive: Bool
    
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showModelSelectionModal = false
    @State private var isHovered = false
    @State private var isHoveredOfflineButton = false
    @AppStorage("model") private var selectedModel: String = "llama3"
    
    @AppStorage("offline") private var offline: Bool = false
    
    @State private var showCheckmark = false
    @AppStorage("clipboardContext") private var clipboardContext: Bool = false
    
    @AppStorage("currentClipboard") private var currentClipboard: String =  "Clipboard is empty"
    @State private var isHoveredClipboardButton = false
    @State private var isHoveringTooltip = false
    
    @State private var showTooltip = false
    @State private var showImagePreview = false
    
    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                if !voiceModeActive {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("TextField").opacity(0.5))
                        .frame(height: 55)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.8), lineWidth: 1)
                                .blur(radius: 4)
                                .padding(4)
                                .blendMode(.overlay)
                        ) .transition(.move(edge: .bottom).combined(with: .opacity))  // This will make it slide from the bottom
                        .animation(.easeInOut(duration: 0.5), value: voiceModeActive) // Add a smooth animation effect
                }
                if !voiceModeActive {
                    HStack {
                        // 📋 Clipboard button on the left
                        ZStack {
                            Button(action: {
                                if !clipboardContext {
                                    // Toggling ON - first show checkmark
                                    showCheckmark = true
                                    
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        clipboardContext = true
                                    }
                                    
                                    // After delay, switch back to clipboard (still green)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            showCheckmark = false
                                        }
                                    }
                                } else {
                                    // Toggling OFF - go directly to white clipboard
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        clipboardContext = false
                                        showCheckmark = false
                                    }
                                }
                                
                                print("clippy")
                            }) {
                                ZStack {
                                    // The clipboard icon - shows when inactive OR after checkmark animation completes
                                    Image(systemName: "doc.on.clipboard")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(clipboardContext ? .green : .white)
                                        .opacity((clipboardContext && showCheckmark) ? 0 : 1)
                                        .rotationEffect(Angle(degrees: (clipboardContext && showCheckmark) ? 90 : 0))
                                    
                                    // The checkmark icon - shows briefly when first activated
                                    Image(systemName: "checkmark.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(.green)
                                        .opacity((clipboardContext && showCheckmark) ? 1 : 0)
                                        .scaleEffect((clipboardContext && showCheckmark) ? 1 : 0.5)
                                }
                                .padding(.leading, 12)
                                .animation(.easeInOut(duration: 0.3), value: clipboardContext || showCheckmark)
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                isHoveredClipboardButton = hovering
                                if hovering {
#if os(iOS)
                                    currentClipboard = UIPasteboard.general.string ?? "Clipboard is empty"
#elseif os(macOS)
                                    currentClipboard = NSPasteboard.general.string(forType: .string) ?? "Clipboard is empty"
#endif
                                    withAnimation {
                                        showTooltip = true
                                    }
                                } else {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        if !isHoveringTooltip {
                                            withAnimation {
                                                showTooltip = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: 30)  // Fixed width for the clipboard button area
                        
                        // ➕ Add Image Button
                        Button(action: {
                            #if os(iOS)
                            // iOS image picker logic placeholder
                            print("Add image tapped (iOS)")
                            #elseif os(macOS)
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = false
                            panel.canChooseDirectories = false
                            panel.allowedContentTypes = [.image]
                            if panel.runModal() == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
                                selectedImage = image
                            }
                            #endif
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.white)
                                .padding(.leading, 8)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 30)

                        // Image preview (if image is selected)
                        if let selectedImage = selectedImage {
                            #if os(iOS)
                            // (Optional) Implement similar button for iOS if needed
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 50, maxHeight: 50)
                                .cornerRadius(6)
                                .padding(.trailing, 8)
                            #elseif os(macOS)
                            Button(action: {
                                showImagePreview = true
                            }) {
                                Image(nsImage: selectedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 50, maxHeight: 50)
                                    .cornerRadius(6)
                                    .padding(.trailing, 8)
                            }
                            .buttonStyle(.plain)
                            #endif
                        }
                        
                        // 📝 TextField
                        TextField("", text: $text)
                            .accessibilityIdentifier("textFieldInput")
                            .textFieldStyle(.plain)
                            .background(.clear)
                            .frame(maxWidth: .infinity, maxHeight: 55)
                            .padding(.horizontal, 8)
                            .focused($isActive)
                            .onSubmit {
                                if text != "" {
                                    sendPrompt(text, image: selectedImage ?? nil, in: viewContext)
                                    text = ""
                                }
                            }
                        
                        // 📨 Send Button on the right
                        Button(action: {
                            if text != "" {
                                sendPrompt(text, image: selectedImage ?? nil, in: viewContext)
                                text = ""
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                                .padding(.trailing, 12)
                        }
                        .buttonStyle(.plain)
                        .background(.clear)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))  // This will make it slide from the bottom
                    .animation(.easeInOut(duration: 0.5), value: voiceModeActive)
                }
            }
            .padding(.horizontal)
            .overlay(
                // Tooltip overlay on the entire component - will not affect layout
                Group {
                    if showTooltip {
                        ZStack {
                            // Background Bubble
                            BubbleWithPointer(pointerPosition: 0.1)
                                .fill(Color("TextField"))
                                .frame(width: 310, height: 220)
                                .shadow(radius: 5)

                            // Tooltip Content
                            ScrollView {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Spacer()
                                        Text("Clipboard Content")
                                            .font(.title)
                                            .bold()
                                            .padding()
                                        Spacer()
                                    }
                                    Text(currentClipboard)
                                        .font(.caption)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.bottom, 20)
                            .frame(width: 300, height: 200)
                        }
                        .frame(width: 310, height: 220)
                        .background(Color.clear)
                        .scaleEffect(showTooltip ? 1 : 0.9)
                        .opacity(showTooltip ? 1 : 0)
                        .position(x: 165, y: -110) // Position from the left edge
                        .transition(.scale)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showTooltip)
                        .onTapGesture {
                            clipboardContext.toggle()
                            print("Tooltip tapped")
                        }
                        .onHover { hovering in
                            isHoveringTooltip = hovering
                            if hovering {
                                withAnimation {
                                    showTooltip = true
                                }
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    if !isHoveredClipboardButton {
                                        withAnimation {
                                            showTooltip = false
                                        }
                                    }
                                }
                            }
                        }
                        .allowsHitTesting(false)
                    }
                }
                .zIndex(10) // Ensure tooltip stays above everything
            )
            
            
            // Buttons underneath the text field
            HStack(spacing: 15) {
                if voiceModeActive {
                    Spacer().transition(.move(edge: .trailing).combined(with: .opacity))  // This will make it slide from the bottom
                        .animation(.easeInOut(duration: 0.5), value: voiceModeActive)
                }
                
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
                    .padding(.vertical, 1)
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
                #if os(iOS)
                .disabled(true)
                #endif
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
                let buttonHeight: CGFloat = {
                    #if os(iOS)
                    return 30
                    #else
                    return 40
                    #endif
                }()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        voiceModeActive.toggle()
                        if voiceModeActive == false {
                            videoModeActive = false
                        }
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "microphone")
                            .font(.system(size: 13))
                            .foregroundColor(voiceModeActive ? .green : .red)
                            #if os(iOS)
                            Text("")
                            #else
                            Text("Voice mode").font(.subheadline)
                            .foregroundColor(voiceModeActive ?  .green.opacity(0.8): .red.opacity(0.8))
                            #endif
                            
                    }
                    
                    .padding(.horizontal, 16)
                    .padding(.vertical, 3)
                    .background(
                        voiceModeActive
                        ? Color("TextField").opacity(0.9)
                        : Color("TextField").opacity(isHoveredOfflineButton ? 0.5 : 0.3)
                    )
                    .cornerRadius(6)
                    .scaleEffect(voiceModeActive ? 0.95 : 1)
                    .animation(.easeInOut(duration: 0.2), value: voiceModeActive)
                }
                .accessibilityIdentifier("VoiceMode") // Assign identifier to the button itself
                .accessibilityElement(children: .combine)
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) { // Animate state change
                        voiceModeActive = true
                        screenshotModeActive = false
                        videoModeActive.toggle()
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera")
                            .font(.system(size: 13))
                            .foregroundColor(videoModeActive ? .green : .red) // Color changes dynamically
                            .transition(.scale.combined(with: .opacity)) // Smooth effect
                        #if os(iOS)
                        Text("")
                        #else
                        Text("Video mode").accessibilityIdentifier("videoModeIdentifier")
                            .font(.subheadline)
                            .foregroundColor(videoModeActive ?  .green.opacity(0.8): .red.opacity(0.8)) // Adjust text color
                        #endif
                            
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        videoModeActive
                        ? Color("TextField").opacity(0.9)  // Darker when active
                        : Color("TextField").opacity(isHoveredOfflineButton ? 0.5 : 0.3) // Lighter when inactive
                    )
                    .cornerRadius(6)
                    .scaleEffect(videoModeActive ? 0.95 : 1) // Slight shrink when pressed
                    .animation(.easeInOut(duration: 0.2), value: videoModeActive) // Smooth transition
                }
                .accessibilityIdentifier("VideoMode") // Assign identifier to the button itself
                .accessibilityElement(children: .combine)
                .buttonStyle(PlainButtonStyle())
//                .disabled(!voiceModeActive)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) { // Animate state change
                        videoModeActive = false
                        
                        screenshotModeActive.toggle()
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 13))
                            .foregroundColor(screenshotModeActive ? .green : .red) // Color changes dynamically
                            .transition(.scale.combined(with: .opacity)) // Smooth effect
                        
                        Text("Screenshot mode")   .accessibilityIdentifier("screenshotModeActive")
                            .font(.subheadline)
                            .foregroundColor(screenshotModeActive ?  .green.opacity(0.8): .red.opacity(0.8)) // Adjust text color
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        screenshotModeActive
                        ? Color("TextField").opacity(0.9)  // Darker when active
                        : Color("TextField").opacity(isHoveredOfflineButton ? 0.5 : 0.3) // Lighter when inactive
                    )
                    .cornerRadius(6)
                    .scaleEffect(screenshotModeActive ? 0.95 : 1) // Slight shrink when pressed
                    .animation(.easeInOut(duration: 0.2), value: screenshotModeActive) // Smooth transition
                }
                .accessibilityIdentifier("screenshotMode") // Assign identifier to the button itself
                .accessibilityElement(children: .combine)
                .buttonStyle(PlainButtonStyle())
//                .disabled(!voiceModeActive)
               
                Spacer()
                if voiceModeActive {
                    Spacer().transition(.move(edge: .trailing).combined(with: .opacity))  // This will make it slide from the bottom
                        .animation(.easeInOut(duration: 0.5), value: voiceModeActive)
                }
            }
            .padding(.horizontal)
            .padding(.top, 5)
            .frame(maxWidth: .infinity, alignment: .leading) // Keep everything aligned
        }
        // Sheet for image preview (macOS)
        #if os(macOS)
        .sheet(isPresented: $showImagePreview) {
            VStack {
                Text("Image Preview")
                    .font(.title)
                    .padding(.top)

                if let selectedImage = selectedImage {
                    Image(nsImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 400, maxHeight: 300)
                        .cornerRadius(10)
                        .padding()
                } else {
                    Text("No image selected.")
                        .foregroundColor(.gray)
                }

                Button("Remove Image") {
                    selectedImage = nil
                    showImagePreview = false
                }
                .padding(.bottom)
            }
            .padding()
            .frame(minWidth: 450, minHeight: 400)
        }
        #endif
        
    }
    
    func captureScreenSnapshot() -> PlatformImage? {
        #if os(macOS)
        guard let screen = NSScreen.main else { return nil }
        let image = CGWindowListCreateImage(screen.frame, .optionOnScreenBelowWindow, kCGNullWindowID, .bestResolution)
        if let cgImage = image {
            return NSImage(cgImage: cgImage, size: screen.frame.size)
        }
        return nil
        #else
        return nil // Implement iOS screenshot logic if needed
        #endif
    }
    
    
    // Function to send message
    func sendPrompt(_ prompt: String, image: PlatformImage?, in context: NSManagedObjectContext) {
        do {
            var finalImage: PlatformImage? = image

            if screenshotModeActive {
                #if os(macOS)
                finalImage = captureScreenSnapshot()
                #elseif os(iOS)
                // Optional: Implement screenshot logic for iOS here
                finalImage = nil
                #endif
            }

            try messageListVM.addMessage(message: prompt, sender: "User", mode: nil, image: finalImage)
            try messageListVM.isStreaming = true
            print("\(messageListVM.isStreaming): state")

            try streamingApiClient.streamResponse(for: prompt, image: finalImage, mode: .text)
            print("✅ Streaming request sent")

            selectedImage = nil
        } catch {
            print("❌ Error sending prompt: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}

struct BubbleWithPointer: Shape {
    var pointerPosition: CGFloat  // Value between 0 (left) and 1 (right)

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let cornerRadius: CGFloat = 10
        let pointerSize: CGFloat = 12  // Triangle size
        let pointerX = rect.width * pointerPosition  // Dynamic pointer position
        
        
        path.addRoundedRect(in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height - pointerSize),
                            cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        
        // 🔺 Triangle Pointer (Dynamic Position)
        path.move(to: CGPoint(x: pointerX - pointerSize, y: rect.height - pointerSize)) // Left point
        path.addLine(to: CGPoint(x: pointerX, y: rect.height)) // Tip
        path.addLine(to: CGPoint(x: pointerX + pointerSize, y: rect.height - pointerSize)) // Right point
        path.closeSubpath()
        
        return path
    }
}

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
    
    var streamingApiClient: StreamingAPIClient!
    @ObservedObject var messageListVM: ChatMessageListViewModel
    var title: String
    @Binding var text: String
    @FocusState var isActive
    @Binding var voiceModeActive: Bool
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
                                    sendPrompt(text, in: viewContext)
                                    text = ""
                                }
                            }
                        
                        // 📨 Send Button on the right
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
                                .padding(.trailing, 12)
                        }
                        .buttonStyle(.plain)
                        .background(.clear)
                    }.transition(.move(edge: .bottom).combined(with: .opacity))  // This will make it slide from the bottom
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
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) { // Animate state change
                        voiceModeActive.toggle()
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "microphone")
                            .font(.system(size: 13))
                            .foregroundColor(voiceModeActive ? .green : .red) // Color changes dynamically
                            .transition(.scale.combined(with: .opacity)) // Smooth effect
                        
                        Text("Voice mode")   .accessibilityIdentifier("OfflineOnlineText")
                            .font(.subheadline)
                            .foregroundColor(voiceModeActive ?  .green.opacity(0.8): .red.opacity(0.8)) // Adjust text color
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        voiceModeActive
                        ? Color("TextField").opacity(0.9)  // Darker when active
                        : Color("TextField").opacity(isHoveredOfflineButton ? 0.5 : 0.3) // Lighter when inactive
                    )
                    .cornerRadius(6)
                    .scaleEffect(voiceModeActive ? 0.95 : 1) // Slight shrink when pressed
                    .animation(.easeInOut(duration: 0.2), value: voiceModeActive) // Smooth transition
                }
                .accessibilityIdentifier("VoiceMode") // Assign identifier to the button itself
                .accessibilityElement(children: .combine)
                .buttonStyle(PlainButtonStyle())
                
               
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
        
    }
    
    // Function to send message
    func sendPrompt(_ prompt: String, in context: NSManagedObjectContext) {
        do {
            try messageListVM.addMessage(message: prompt, sender: "User" )
            try messageListVM.isStreaming = true
            print("\(messageListVM.isStreaming): state")
            
            try streamingApiClient.streamResponse(for: prompt, image: nil)
            print("✅ Streaming request sent")
            
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
        
        // 🔲 Rounded Rect (Main Bubble)
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

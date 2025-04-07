import SwiftUI

struct MessageRow: View {
    let message: Message?
    let thinkingContent: String?
    let tempMessage: tempMessage?
    let hoveredMessageID: UUID?
    let deleteMessage: (Message) -> Void
    let saveMessage: (Message) -> Void
    let setHoveredMessage: (UUID?) -> Void
    
    @State private var isThinkingModalPresented: Bool = false
    @State private var clipboardModalPresented: Bool = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            // Show temp message or regular message
            if tempMessage != nil {
                HStack {
                    VStack(alignment: .leading) {
                        Text(tempMessage?.message ?? "")
                            .lineLimit(nil) // Remove any line limit
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(tempMessage?.sender ?? "")
                            .font(.caption)
                            .foregroundColor(.white)
                            .bold()
                    }
                    Spacer()
                }
                .id(tempMessage?.id)
            } else if message?.sender == "User" {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(message?.message ?? "")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(message!.formattedTimestamp)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color("TextField"))
                    .cornerRadius(12)
                }
                .id(message?.id)
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text(message?.message ?? "")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(message?.sender ?? "")
                            .font(.caption)
                            .foregroundColor(.white)
                            .bold()
                    }
                    Spacer()
                }
                .id(message?.id)
            }

            // Thinking content button
           
            
            // Buttons for delete, save, etc.
            HStack(spacing: 15) {
                Button(action: { deleteMessage(message!) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                if let clipboardContext = message?.clipboardContext, !clipboardContext.isEmpty {
                    Button(action: {
                        // Show the modal when the button is pressed
                        
                        clipboardModalPresented.toggle()
                    }) {
                        Image(systemName: "contextualmenu.and.cursorarrow")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }.buttonStyle(PlainButtonStyle())
                    
                }
                if let thinkingContent = message?.thinkingContent, !thinkingContent.isEmpty {
                    Button(action: {
                        // Show the modal when the button is pressed
                        isThinkingModalPresented.toggle()
                    }) {
                        Image(systemName: "brain")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }.buttonStyle(PlainButtonStyle())
                    
                }
                Button(action: { saveMessage(message!) }) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                if message?.sender == "Merlin" {
                    Spacer()
                }
            }
            .padding(.vertical)
            .opacity(hoveredMessageID == message?.id ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.2), value: hoveredMessageID)
        }
        .onHover { hovering in
            setHoveredMessage(hovering ? message?.id : nil)
        }
        // Modal for thinking content
        .sheet(isPresented: $clipboardModalPresented) {
            VStack(alignment: .leading) {
                Text("Clipboard Context")
                    .font(.headline)
                    .padding()

                ScrollView {
                    Text(message?.clipboardContext ?? "")
                        .font(.body)
                        .padding()
                }

                Button("Close") {
                    clipboardModalPresented.toggle()
                }
                .padding()
                
                .foregroundColor(.white)
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("TextField"))
        }
        .sheet(isPresented: $isThinkingModalPresented) {
            VStack {
                Text("Thinking Content")
                    .font(.headline)
                    .padding()
                
                ScrollView {
                    Text(message?.thinkingContent ?? "")
                        .font(.body)
                        .padding()
                }
                
                Button("Close") {
                    isThinkingModalPresented.toggle() // Close modal
                }
                .padding()
                
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


import SwiftUI
import EventKit


struct EventView: View {
    var event: EKEvent
    var frame: CGRect
    var isEditable: Bool
    var isActive: Bool
    var onResizeTop: ((CGFloat) -> Void)? = nil
    var onResizeBottom: ((CGFloat) -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var isHoveringTop = false
    @State private var isHoveringBottom = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)  // <-- important!

                Text("\(event.startDate.formatted(date: .omitted, time: .shortened)) - \(event.endDate.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Text(event.location ?? "")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)

                if isEditable && isActive {
                    HStack {
                        Spacer()
                        Button(action: {
                            onDelete?()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding([.top, .trailing], 6)
                    }
                }

                if !isEditable {
                    HStack {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                        Spacer()
                    }
                }
            }
            .padding(5)
            .frame(maxHeight: frame.height * 0.9, alignment: .top)  // limit max height overall

            if isEditable {
                VStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 10)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            isHoveringTop = hovering
                            updateCursor(isHovering: hovering)
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    onResizeTop?(value.translation.height)
                                }
                        )
                    Spacer()
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 10)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            isHoveringBottom = hovering
                            updateCursor(isHovering: hovering)
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    onResizeBottom?(value.translation.height)
                                }
                        )
                }
            }
        }
        .frame(width: frame.width - 2, height: frame.height, alignment: .topLeading)
        .background(
            (isEditable ? Color.purple : Color.gray)
                .opacity(isActive ? 1.0 : 0.6)
        )
        .cornerRadius(6)
        .offset(x: frame.minX + 4, y: frame.minY - 40)
    }

    func updateCursor(isHovering: Bool) {
        #if os(macOS)
        DispatchQueue.main.async {
            if isHovering {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
        #endif
    }
}

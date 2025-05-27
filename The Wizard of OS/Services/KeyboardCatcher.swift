import SwiftUI

#if os(macOS)
import AppKit

struct KeyboardCatcher: NSViewRepresentable {
    var onDelete: () -> Void

    class Coordinator: NSObject, NSTextFieldDelegate {
        var onDelete: () -> Void

        init(onDelete: @escaping () -> Void) {
            self.onDelete = onDelete
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                onDelete()
                return true
            }
            return false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDelete: onDelete)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isBordered = false
        textField.isHidden = true
        textField.delegate = context.coordinator
        DispatchQueue.main.async {
            textField.window?.makeFirstResponder(textField)
        }
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {}
}

#else

struct KeyboardCatcher: View {
    var onDelete: () -> Void

    var body: some View {
        EmptyView() // No-op on iOS
    }
}

#endif

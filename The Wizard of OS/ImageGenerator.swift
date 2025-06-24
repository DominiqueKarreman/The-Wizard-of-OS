import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Simple placeholder for image generation. Replace with real Foundation Model logic.
final class ImageGenerator {
    init() async throws {}
    
    /// Generates a simple image containing the prompt text.
    func generateImage(from prompt: String) async throws -> PlatformImage {
        #if os(iOS)
        let size = CGSize(width: 400, height: 200)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.systemPurple.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 28),
            .foregroundColor: UIColor.yellow
        ]
        let textRect = CGRect(x: 10, y: 80, width: 380, height: 40)
        (prompt as NSString).draw(in: textRect, withAttributes: attributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
        #elseif os(macOS)
        let size = NSSize(width: 400, height: 200)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.systemPurple.setFill()
        NSRect(origin: .zero, size: size).fill()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 28),
            .foregroundColor: NSColor.yellow
        ]
        let str = NSAttributedString(string: prompt, attributes: attrs)
        str.draw(in: NSRect(x: 10, y: 80, width: 380, height: 40))
        image.unlockFocus()
        return image
        #endif
    }
}

#if os(iOS)
typealias PlatformImage = UIImage
#elseif os(macOS)
typealias PlatformImage = NSImage
#endif

//
//  ChatStreamTextEffect.swift
//  The Wizard of OS
//
//  Created by Dominique Karreman on 3/10/25.
//


import SwiftUI

struct ChatStreamTextEffect: View {
    let text: String
    let fontSize: Double
    let startDelay: Double  // Delay before the animation starts
#if os(iOS)
    let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
    #endif
    
    @State private var displayedText = ""
    let chunkSize: Int = 1  // Number of characters to reveal at a time
    let delayPerChunk: Double  // Delay between revealing each chunk
    var font: String?
    
    @State private var currentIndex = 0
    
    var body: some View {
        if font != "small"{
            Text(displayedText)
                .font(.custom("Anek Devanagari Bold", fixedSize: fontSize))
                .fontWeight(.regular)
                .foregroundColor(.primary)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                        startTextStreaming()
                    }
                }
        } else {
            Text(displayedText)
                .font(.system(size:fontSize))
                .fontWeight(.regular)
                .foregroundColor(.primary)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                        startTextStreaming()
                    }
                }
        }
    }

    private func startTextStreaming() {
        // Start a timer that fires every `delayPerChunk` seconds to update the displayed text.
        Timer.scheduledTimer(withTimeInterval: delayPerChunk, repeats: true) { timer in
            guard currentIndex < text.count else {
                timer.invalidate() // Stop the timer when all text is displayed
                return
            }
            
            let endIndex = min(currentIndex + chunkSize, text.count)
            let chunk = String(text[text.index(text.startIndex, offsetBy: currentIndex)..<text.index(text.startIndex, offsetBy: endIndex)])
            displayedText += chunk
#if os(iOS)
            impactFeedback.impactOccurred()
#endif
            currentIndex = endIndex
        }
    }
}



struct Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

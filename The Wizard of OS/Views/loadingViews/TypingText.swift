//
//  TypingText.swift
//  The Wizard of OS
//
//  Created by Dominique Karreman on 5/20/25.
//
import SwiftUI

struct TypingText: View {
    let fullText: String
    @State private var displayText = ""
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var index = 0

    var body: some View {
        Text(displayText)
            .font(.headline)
            .onReceive(timer) { _ in
                if index < fullText.count {
                    let nextIndex = fullText.index(fullText.startIndex, offsetBy: index)
                    displayText.append(fullText[nextIndex])
                    index += 1
                } else {
                    timer.upstream.connect().cancel()
                }
            }
    }
}

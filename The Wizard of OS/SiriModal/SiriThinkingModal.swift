//
//  SiriThinkingModal.swift
//  The Wizard of OS
//
//  Created by Dominique Karreman on 3/26/25.
//


import SwiftUI

@available(macOS 15.0, *)
struct SiriThinkingModal: View {
    let thinkingContent: String
    @State private var state: SiriView.SiriState = .thinking
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)  // Background color
            VStack {
                SiriView()  // Siri-style animation
                    .frame(height: 400)  // Adjust height as needed
                
                Text(thinkingContent)  // Displaying thinking content
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                
                Button("Close") {
                    state = .none
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
    }
}

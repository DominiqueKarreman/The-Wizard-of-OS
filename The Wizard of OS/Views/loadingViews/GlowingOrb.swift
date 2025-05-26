//
//  GlowingOrb.swift
//  The Wizard of OS
//
//  Created by Dominique Karreman on 5/20/25.
//
import SwiftUI

struct GlowingOrb: View {
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(RadialGradient(gradient: Gradient(colors: [Color.purple, Color.black]), center: .center, startRadius: 5, endRadius: 30))
            .frame(width: 30, height: 30)
            .scaleEffect(pulse ? 1.2 : 0.8)
            .shadow(color: .purple, radius: 10)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
            .onAppear {
                pulse = true
            }
    }
}

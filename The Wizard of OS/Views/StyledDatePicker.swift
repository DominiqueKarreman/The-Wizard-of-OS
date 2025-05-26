//
//  StyledDatePicker.swift
//  The Wizard of OS
//
//  Created by Dominique Karreman on 5/17/25.
//
import SwiftUI

@ViewBuilder
func customStyledDatePicker(date: Binding<Date>) -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#8B7CFF"),
                        Color(hex: "#BEB8EB")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(0.25) // ✅ Apply here for full shape transparency

            .overlay(
                // Simulated inner shadow
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                    .blur(radius: 1.5)
                    .offset(x: 1, y: 1)
                    .mask(
                        RoundedRectangle(cornerRadius: 12).fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black, Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
            )

        DatePicker(
            "",
            selection: date,
            displayedComponents: [.hourAndMinute, .date]
        )
        .labelsHidden()
        .datePickerStyle(.compact)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundColor(.white)
    }
    .frame(height: 34)
}

#Preview {
    customStyledDatePicker(date: .constant(Date()))
}

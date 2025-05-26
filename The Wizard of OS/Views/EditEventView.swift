//
//  EditEventView.swift
//  The Wizard of OS
//
//  Created by Dominique Karreman on 5/17/25.
//
import SwiftUI
import EventKit

struct EditEventView: View {
    @Binding var event: EKEvent
    var calendarManager: CalendarManager  // Pass your calendar manager here
    var onClose: () -> Void

    var body: some View {
        ZStack {
            // Background
            Image("editbackground")
                .resizable()
                .frame(width: 600, height: 260)
                .scaledToFill()
                .clipped()
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 10) {
                Text("Edit Event")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.bottom, 5)

                // Title TextField with background and overlay
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#8B7CFF"), Color(hex: "#BEB8EB")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .opacity(0.25)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                                .blur(radius: 1.5)
                                .offset(x: 1, y: 1)
                                .mask(
                                    RoundedRectangle(cornerRadius: 12).fill(
                                        LinearGradient(gradient: Gradient(colors: [Color.black, Color.clear]),
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing)
                                    )
                                )
                        )

                    TextField("Title", text: Binding(
                        get: { event.title ?? "" },
                        set: {
                            event.title = $0
                            calendarManager.updateEvent(event, newStart: event.startDate, newEnd: event.endDate)
                        }
                    ))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .foregroundColor(.white)
                    .font(.body)
                }
                .frame(width: 400, height: 34)

                // Date pickers with label "until"
                HStack(spacing: 8) {
                    customStyledDatePicker(date: Binding(
                        get: { event.startDate },
                        set: { newStart in
                            calendarManager.updateEvent(event, newStart: newStart, newEnd: event.endDate)
                        }
                    ))

                    Text("until")
                        .foregroundColor(.white)
                        .font(.body)
                        .padding(.horizontal, 2)

                    customStyledDatePicker(date: Binding(
                        get: { event.endDate },
                        set: { newEnd in
                            calendarManager.updateEvent(event, newStart: event.startDate, newEnd: newEnd)
                        }
                    ))
                }

                // Buttons: Optimize & Save
                HStack(spacing: 16) {
                    Button(action: {
                        // Implement Optimize action here
                    }) {
                        Text("Optimize")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#8B7CFF"), Color(hex: "#BEB8EB")]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .opacity(0.25)
                                .overlay(
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
                            )
                            .cornerRadius(12)
                    }

                    Button(action: {
                        onClose()
                    }) {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Color(hex: "#BC2CB2")
                                .overlay(
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
                            )
                            .cornerRadius(12)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 400, height: 44)

                Spacer()
            }
            .padding()
            .frame(width: 260, height: 200)
        }
        .frame(width: 260, height: 200)
    }
}

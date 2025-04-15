//
//  The_Wizard_of_OSApp.swift
//  The Wizard of OS
//
//  Created by Dominique Karreman on 3/6/25.
//

import SwiftUI
import SwiftData
import UserNotifications
import CloudKit

struct APIConstants {
    static let baseURL = "https://5191-145-44-53-171.ngrok-free.app"
}
@available(macOS 15.0, *)
@main
struct TheWizardOfOSApp: App {
    let persistenceController = PersistenceController.shared

    @AppStorage("voiceModeActive") var voiceModeActive: Bool = false // Store voice mode state

    var body: some Scene {
        #if os(macOS)
        // macOS: Track sidebar state
        
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .commands {
            @AppStorage("clipboardContext") var clipboardContext: Bool = false

            CommandGroup(after: .sidebar) {
                Button("Toggle Sidebar") {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Toggle Clipboard Context") {
                    clipboardContext.toggle()
                }
                .keyboardShortcut("k", modifiers: .command)

                // Add keyboard shortcut to toggle voice mode
                Button("Toggle Voice Mode") {
                    voiceModeActive.toggle()
                }
                .keyboardShortcut("v", modifiers: [.command, .shift]) // Change "v" to your preferred key
            }
        }
        .windowStyle(.hiddenTitleBar) // Hide title bar in macOS

        #else
        WindowGroup {
            iOSMainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        #endif
    }
}
#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

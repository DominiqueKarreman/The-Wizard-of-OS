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
    static let baseURL = "https://b57a-2a02-a44f-108f-0-7166-a88c-92a8-d261.ngrok-free.app"
}

@available(macOS 15.0, *)
@main
struct TheWizardOfOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        #if os(macOS)
        // macOS: Track sidebar state
        
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .commands {
            CommandGroup(after: .sidebar) {
                Button("Toggle Sidebar") {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                }
                .keyboardShortcut("s", modifiers: .command) // ⌘B for macOS
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

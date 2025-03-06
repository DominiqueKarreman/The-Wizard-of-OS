//
//  iOSMainTabView.swift
//  The Wizard of OS
//
//  Created by Dominique Karreman on 3/26/25.
//
import SwiftUI

struct iOSMainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var body: some View {
        TabView {
            ContentView() .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            CalendarView()
                .tabItem {
                    Label("Messages", systemImage: "message")
                }

            CalendarView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

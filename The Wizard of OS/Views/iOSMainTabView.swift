import SwiftUI

struct iOSMainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0  // Track selected tab

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    VStack {
                        Image(systemName: "person.bubble.fill")
                        Text("Merlin")
                            .foregroundColor(selectedTab == 0 ? .white : .gray) // Change text color
                    }
                }
                .tag(0)


            SettingsView()
                .tabItem {
                    VStack {
                        Image(systemName: "gear")
                        Text("Settings")
                            .foregroundColor(selectedTab == 2 ? .white : .gray)
                    }
                }
                .tag(2)
        }
    }
}

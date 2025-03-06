import SwiftUI

struct MainTabView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme  // Access color scheme
    
    var body: some View {
        NavigationSplitView {
             // Hide sidebar when false
              
                List {
                    Divider()
                    NavigationLink(destination: ContentView().environment(\.managedObjectContext, viewContext)) {
                        Label(" M.E.R.L.I.N", systemImage: "person.bubble.fill")
                            .font(.title)
                            
                    }

                    NavigationLink(destination: CalendarView()) {
                        Label(" Calendar", systemImage: "calendar").font(.title)
                    }

                    NavigationLink(destination: CalendarView()) {
                        Label(" Settings", systemImage: "gearshape.fill").font(.title)
                    }
                }
                .listStyle(.sidebar).offset(y: 100)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(hex: "D6A9FF"), location: 0.0),
                            Gradient.Stop(color: Color(hex: "BC2CB2"), location: 0.31),
                            Gradient.Stop(color: Color(hex: "8B7CFF"), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        colorScheme == .dark ? Color.black.opacity(0.5) : Color.clear
                    ) // Dark mode overlay
                )
                .frame(minWidth: 200)
                .edgesIgnoringSafeArea(.all)  // Ensure the gradient covers the full sidebar
            
        } detail: {
            ContentView()
        }
    }
}

#Preview {
    MainTabView()
}

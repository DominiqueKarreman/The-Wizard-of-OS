import Foundation
import Network
import SwiftUI

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected: Bool = true
    @AppStorage("offline") private var offline: Bool = false

    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
                self.offline = path.status != .satisfied // Automatically sync with offline state
                print("🌐 Network status changed: \(self.isConnected ? "Online" : "Offline")")
            }
        }
        monitor.start(queue: queue)
    }
}

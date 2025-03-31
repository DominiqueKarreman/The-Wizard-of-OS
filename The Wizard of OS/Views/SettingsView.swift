import SwiftUI

struct SettingsView: View {
    // Define the list of available models
    let models = ["llama3", "deepseek-r1"]
    
    // Use @AppStorage to bind directly to UserDefaults
    @AppStorage("model") private var selectedModel: String = "llama3"
    @AppStorage("darkMode") private var isDarkModeEnabled: Bool = false
    @AppStorage("notificationsEnabled") private var areNotificationsEnabled: Bool = true
    
    var body: some View {
        List {
            // Section for Model Selection
            Section(header: Text("Model Selection")) {
                Picker("Choose Model", selection: $selectedModel) {
                    ForEach(models, id: \.self) { model in
                        Text(model)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedModel) { newValue in
                    // Model selection is automatically handled by @AppStorage
                    print("Selected model: \(newValue)")
                }
            }
            
            // Section for General Preferences
            Section(header: Text("General Preferences")) {
                Toggle("Dark Mode", isOn: $isDarkModeEnabled)
                    .onChange(of: isDarkModeEnabled) { newValue in
                        // Dark mode setting is automatically handled by @AppStorage
                        print("Dark Mode: \(newValue ? "Enabled" : "Disabled")")
                    }
                
                Toggle("Enable Notifications", isOn: $areNotificationsEnabled)
                    .onChange(of: areNotificationsEnabled) { newValue in
                        // Notifications setting is automatically handled by @AppStorage
                        print("Notifications: \(newValue ? "Enabled" : "Disabled")")
                    }
            }
            
            // Section for Resetting Settings
            Section {
                Button("Reset to Default") {
                    // Reset settings to defaults
                    UserDefaults.standard.removeObject(forKey: "model")
                    UserDefaults.standard.removeObject(forKey: "darkMode")
                    UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
                    
                    // Reset the state variables to their default values
                    selectedModel = "llama3"
                    isDarkModeEnabled = false
                    areNotificationsEnabled = true
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Settings")
        .listStyle(PlainListStyle()) // Use PlainListStyle for macOS compatibility
    }
}

#Preview {
    SettingsView()
}

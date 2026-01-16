import SwiftUI

/// Settings/Preferences View
struct SettingsView: View {
    @ObservedObject var billing = BillingManager.shared
    @ObservedObject var thermal = ThermalManager.shared
    
    @AppStorage("minima.hotkey") private var hotkey: String = "⌘ Space"
    @AppStorage("minima.autoLaunch") private var autoLaunch: Bool = true
    @AppStorage("minima.showInDock") private var showInDock: Bool = false
    @AppStorage("minima.enableVision") private var enableVision: Bool = true
    @AppStorage("minima.enableWebSearch") private var enableWebSearch: Bool = true
    
    var body: some View {
        TabView {
            // General
            Form {
                Section("Activation") {
                    HStack {
                        Text("Hotkey")
                        Spacer()
                        Text(hotkey)
                            .foregroundColor(.secondary)
                    }
                    Toggle("Launch at Login", isOn: $autoLaunch)
                    Toggle("Show in Dock", isOn: $showInDock)
                }
                
                Section("Features") {
                    Toggle("Enable Vision (Screen Reading)", isOn: $enableVision)
                    Toggle("Enable Web Search", isOn: $enableWebSearch)
                }
            }
            .tabItem { Label("General", systemImage: "gear") }
            
            // Models
            Form {
                Section("Current Model") {
                    HStack {
                        Text("Scout (3B)")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    HStack {
                        Text("Sovereign (7B)")
                        Spacer()
                        if billing.isPro {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Text("Pro Required")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Performance") {
                    HStack {
                        Text("Thermal State")
                        Spacer()
                        Text(thermal.currentMode.rawValue.capitalized)
                            .foregroundColor(thermal.currentMode == .survival ? .red : .green)
                    }
                }
            }
            .tabItem { Label("Models", systemImage: "cpu") }
            
            // Account
            Form {
                Section("Subscription") {
                    if billing.isPro {
                        HStack {
                            Text("Minima Pro")
                            Spacer()
                            Text("Active")
                                .foregroundColor(.green)
                        }
                    } else {
                        Button("Upgrade to Pro") {
                            // Show paywall
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                Section("Account") {
                    if AuthManager.shared.isAuthenticated {
                        Text("Signed in with Apple")
                    } else {
                        Button("Sign In") {
                            AuthManager.shared.signIn()
                        }
                    }
                }
            }
            .tabItem { Label("Account", systemImage: "person.circle") }
            
            // Privacy
            Form {
                Section("Permissions") {
                    HStack {
                        Text("Screen Recording")
                        Spacer()
                        Button("Open Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                        }
                    }
                    HStack {
                        Text("Accessibility")
                        Spacer()
                        Button("Open Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                        }
                    }
                }
                
                Section("Data") {
                    Text("All processing happens on-device. No data is sent to external servers.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .tabItem { Label("Privacy", systemImage: "lock.shield") }
        }
        .frame(width: 450, height: 350)
    }
}

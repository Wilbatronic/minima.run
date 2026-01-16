import SwiftUI

/// Menu Bar Widget for quick access on macOS
@available(macOS 13.0, *)
struct MenuBarWidget: View {
    @ObservedObject var brain = MinimaBrain.shared
    @ObservedObject var billing = BillingManager.shared
    @ObservedObject var thermal = ThermalManager.shared
    
    @State private var quickQuery: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quick Input
            HStack {
                TextField("Quick question...", text: $quickQuery)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        brain.ask(quickQuery)
                        quickQuery = ""
                    }
                
                Button(action: { brain.ask(quickQuery); quickQuery = "" }) {
                    Image(systemName: "arrow.up.circle.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            Divider()
            
            // Status
            HStack {
                Circle()
                    .fill(thermal.currentMode == .sovereign ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(thermal.currentMode.rawValue.capitalized)
                    .font(.caption)
                Spacer()
                Text(billing.isPro ? "Pro" : "Free")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Quick Actions
            Button("Open Minima") {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            
            Button("Settings...") {
                // Open settings window
            }
            
            Divider()
            
            Button("Quit Minima") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 280)
    }
}

/// In App.swift, add this to create the menu bar extra:
/*
 @main
 struct MinimaApp: App {
     var body: some Scene {
         WindowGroup { ... }
         
         MenuBarExtra("Minima", systemImage: "sparkles") {
             MenuBarWidget()
         }
         .menuBarExtraStyle(.window)
     }
 }
*/

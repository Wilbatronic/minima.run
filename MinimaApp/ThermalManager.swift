import Foundation
import Combine

/// "The Thermostat"
/// Monitors device thermal state and proactively degrades quality BEFORE the OS throttles.
/// This keeps UX smooth instead of sudden FPS drops.
public class ThermalManager: ObservableObject {
    public static let shared = ThermalManager()
    
    public enum PerformanceMode: String {
        case sovereign  // Full power: 7B model, 4K vision
        case balanced   // Medium: 3B model, 1080p vision
        case survival   // Low: 3B model, 720p vision, skip frames
    }
    
    @Published public var currentMode: PerformanceMode = .sovereign
    @Published public var thermalState: ProcessInfo.ThermalState = .nominal
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Subscribe to thermal notifications
        NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateMode()
            }
            .store(in: &cancellables)
        
        // Initial check
        updateMode()
    }
    
    private func updateMode() {
        let state = ProcessInfo.processInfo.thermalState
        self.thermalState = state
        
        switch state {
        case .nominal:
            currentMode = .sovereign
        case .fair:
            currentMode = .sovereign // Still fine
        case .serious:
            // Proactive downgrade BEFORE critical
            currentMode = .balanced
            print("[Thermal] Serious heat. Switching to Balanced mode.")
        case .critical:
            currentMode = .survival
            print("[Thermal] CRITICAL. Survival mode engaged.")
        @unknown default:
            currentMode = .balanced
        }
    }
    
    /// Returns recommended vision resolution based on thermal state
    public var recommendedResolution: CGSize {
        switch currentMode {
        case .sovereign: return CGSize(width: 2048, height: 2048)
        case .balanced:  return CGSize(width: 1024, height: 1024)
        case .survival:  return CGSize(width: 512, height: 512)
        }
    }
    
    /// Returns whether to use the 7B or 3B model
    public var shouldUseLargeModel: Bool {
        return currentMode == .sovereign
    }
}

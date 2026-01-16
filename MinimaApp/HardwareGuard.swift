import Foundation
import Metal

public struct HardwareRequirements {
    public static let minRAM_Mac: UInt64 = 8 * 1024 * 1024 * 1024 // 8GB
    public static let minRAM_iOS: UInt64 = 8 * 1024 * 1024 * 1024 // 8GB (A17 Pro)
}

public struct HardwareGuard {
    
    public enum CapabilityError: Error, LocalizedError {
        case insufficientRAM(found: UInt64, required: UInt64)
        case unsupportedChip
        case simulator
        
        public var errorDescription: String? {
            switch self {
            case .insufficientRAM(let found, let required):
                let fGb = Double(found) / 1024 / 1024 / 1024
                let rGb = Double(required) / 1024 / 1024 / 1024
                return "Insufficient RAM. Found \(String(format: "%.1f", fGb))GB, required \(String(format: "%.0f", rGb))GB."
            case .unsupportedChip:
                return "Models older than iPhone 15 Pro (A17 Pro) or M1 Macs are not supported due to NPU/Memory bandwidth constraints."
            case .simulator:
                return "Running on Simulator. Performance will be degraded (No Neural Engine)."
            }
        }
    }
    
    public static func validate() throws {
        // 1. Check Simulator
        #if targetEnvironment(simulator)
        print("Warning: Running on Simulator.")
        // In dev, we might allow it, but warn.
        #endif
        
        // 2. Check RAM
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        #if os(iOS)
        if physicalMemory < HardwareRequirements.minRAM_iOS {
            throw CapabilityError.insufficientRAM(found: physicalMemory, required: HardwareRequirements.minRAM_iOS)
        }
        #elseif os(macOS)
        if physicalMemory < HardwareRequirements.minRAM_Mac {
            throw CapabilityError.insufficientRAM(found: physicalMemory, required: HardwareRequirements.minRAM_Mac)
        }
        #endif
        
        // 3. Check Metal Family (Proxy for Chip Generation)
        // .apple7 corresponds roughly to A14/M1 features.
        // A17 Pro supports .apple9
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw CapabilityError.unsupportedChip
        }
        
        if !device.supportsFamily(.apple7) {
             throw CapabilityError.unsupportedChip
        }
        
        // Strict check for iOS 17 features if needed
        #if os(iOS)
        // A17 specific check if we rely on specific raytracing or mesh shaders
        // For now, apple7 (M1 level) is a safe floor for "runs at all"
        #endif
    }
}

import Foundation

/// "The Director"
/// Enforces strict thread scheduling policies to exploit Apple Silicon's P-Core/E-Core topology.
public class ThreadManager {
    
    // We want the Brain (LLM) to live on P-Cores (Performance).
    // We want the Eyes (Capture) to live on E-Cores (Efficiency) to save battery.
    
    public static func pinToPerformanceCores() {
        // 1. Set QoS Class to User Interactive (Highest Priority)
        var qos = QOS_CLASS_USER_INTERACTIVE
        pthread_set_qos_class_self_np(qos, 0)
        
        // 2. Promote Thread Priority (Mach API)
        // This hints the scheduler to keep this on the big cores (Firestorm/Avalanche/Everest)
        // thread_policy_set... (Requires C bridging, keeping it simple to qos_class for Swift)
    }
    
    public static func pinToEfficiencyCores() {
        // For the background capture loop
        var qos = QOS_CLASS_BACKGROUND
        pthread_set_qos_class_self_np(qos, 0)
    }
    
    public static func executeOnPCore(_ block: @escaping () -> Void) {
        let thread = Thread {
            pinToPerformanceCores()
            block()
        }
        thread.qualityOfService = .userInteractive
        thread.start()
    }
}

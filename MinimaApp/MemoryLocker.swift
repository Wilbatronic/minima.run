import Foundation

/// "The Anchor"
/// Prevents the OS from swapping or compressing crucial model weights.
public class MemoryLocker {
    
    // Apple Silicon "Trick":
    // The Neural Engine and GPU share memory. If that memory is compressed by the OS, 
    // the GPU triggers a page fault and waits for CPU decompression. This kills latency.
    
    public static func lock(pointer: UnsafeRawPointer, size: Int) {
        // 1. Tell kernel we will need this (Pre-paging)
        // MADV_WILLNEED: Paginates it in immediately.
        madvise(UnsafeMutableRawPointer(mutating: pointer), size, MADV_WILLNEED)
        
        // 2. Lock it (Pinning)
        // mlock: Disables paging for this range.
        let result = mlock(pointer, size)
        
        if result == 0 {
            print("[MemoryLocker] Successfully wired \(size / 1024 / 1024)MB to RAM.")
        } else {
            print("[MemoryLocker] Failed to wire memory. Errno: \(errno)")
        }
    }
    
    public static func unlock(pointer: UnsafeRawPointer, size: Int) {
        munlock(pointer, size)
    }
}

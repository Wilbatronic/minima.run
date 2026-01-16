import XCTest
@testable import Minima

/// Unit Tests for Core Brain Logic
final class MinimaBrainTests: XCTestCase {
    
    // MARK: - Prompt Cache Tests
    
    func testPromptCacheWarmUp() async {
        let cache = PromptCache.shared
        
        cache.warmUp(systemPrompt: "You are Minima, a helpful assistant.") { prompt in
            // Mock tokenizer
            return prompt.map { Int32($0.asciiValue ?? 0) }
        }
        
        // Wait for async warm-up
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertGreaterThan(cache.cachedTokenCount, 0)
    }
    
    func testPromptCacheInvalidate() {
        let cache = PromptCache.shared
        cache.invalidate()
        
        XCTAssertNil(cache.getCachedTokens())
    }
    
    // MARK: - Sliding Window Tests
    
    func testSlidingWindowAppend() {
        let window = SlidingWindowContext.shared
        window.clear()
        
        let tokens: [Int32] = Array(0..<100).map { Int32($0) }
        window.append(newTokens: tokens)
        
        let context = window.getContext()
        XCTAssertEqual(context.tokens.count, 100)
    }
    
    // MARK: - Encryption Tests
    
    func testEncryptionRoundTrip() throws {
        let manager = EncryptionManager.shared
        let original = "Hello, World! This is a secret message."
        
        let encrypted = try manager.encryptString(original)
        let decrypted = try manager.decryptString(encrypted)
        
        XCTAssertEqual(original, decrypted)
    }
    
    // MARK: - Feature Flags Tests
    
    func testFeatureFlagDefault() {
        let flags = FeatureFlags.shared
        
        XCTAssertTrue(flags.isEnabled("flashAttention"))
        XCTAssertFalse(flags.isEnabled("nonExistentFeature"))
    }
    
    func testFeatureFlagOverride() {
        let flags = FeatureFlags.shared
        
        flags.setFlag("testFeature", enabled: true)
        XCTAssertTrue(flags.isEnabled("testFeature"))
        
        flags.setFlag("testFeature", enabled: false)
        XCTAssertFalse(flags.isEnabled("testFeature"))
    }
    
    // MARK: - Analytics Tests
    
    func testAnalyticsDisabledByDefault() {
        let analytics = Analytics.shared
        
        // Should not crash when disabled
        analytics.track(.appLaunch)
    }
    
    // MARK: - Chart Generator Tests
    
    func testChartDataParsing() {
        let generator = ChartGenerator.shared
        
        let input = """
        CHART:bar
        TITLE:Sales
        DATA:Q1=100,Q2=150,Q3=120,Q4=200
        """
        
        let data = generator.parseChartData(from: input)
        
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.type, .bar)
        XCTAssertEqual(data?.title, "Sales")
        XCTAssertEqual(data?.dataPoints.count, 4)
    }
}

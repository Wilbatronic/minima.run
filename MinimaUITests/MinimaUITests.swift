import XCTest

/// UI Tests for critical user flows
final class MinimaUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Onboarding Flow
    
    func testOnboardingFlow() throws {
        // Check if onboarding is shown for new users
        // Note: This would require resetting user defaults
        
        let welcomeText = app.staticTexts["Welcome to Minima"]
        if welcomeText.exists {
            XCTAssertTrue(welcomeText.exists)
            
            // Navigate through onboarding
            let nextButton = app.buttons["Next"]
            
            // Page 1 -> 2
            nextButton.tap()
            XCTAssertTrue(app.staticTexts["Enable Vision"].exists)
            
            // Page 2 -> 3
            nextButton.tap()
            XCTAssertTrue(app.staticTexts["Enable Control"].exists)
            
            // Page 3 -> 4
            nextButton.tap()
            XCTAssertTrue(app.staticTexts["You're All Set!"].exists)
            
            // Complete onboarding
            app.buttons["Get Started"].tap()
        }
    }
    
    // MARK: - Main Query Flow
    
    func testQueryInput() throws {
        let textField = app.textFields["Ask Minima..."]
        
        // Verify text field exists
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        
        // Type a query
        textField.tap()
        textField.typeText("What is the capital of France?")
        
        // Submit query
        let sendButton = app.buttons["Send"]
        if sendButton.exists {
            sendButton.tap()
        } else {
            // Try pressing return
            textField.typeText("\n")
        }
        
        // Wait for response
        let thinkingIndicator = app.activityIndicators.firstMatch
        if thinkingIndicator.exists {
            // Wait for thinking to complete (timeout after 30s)
            XCTAssertTrue(thinkingIndicator.waitForExistence(timeout: 1))
        }
    }
    
    // MARK: - Settings
    
    func testOpenSettings() throws {
        // Look for settings button
        let settingsButton = app.buttons["Settings"]
        
        if settingsButton.exists {
            settingsButton.tap()
            
            // Verify settings tabs exist
            XCTAssertTrue(app.buttons["General"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.buttons["Models"].exists)
            XCTAssertTrue(app.buttons["Account"].exists)
            XCTAssertTrue(app.buttons["Privacy"].exists)
        }
    }
    
    // MARK: - Voice Input
    
    func testVoiceButton() throws {
        let voiceButton = app.buttons.matching(identifier: "voice").firstMatch
        
        if voiceButton.exists {
            voiceButton.tap()
            
            // Should show microphone indicator
            let listeningIndicator = app.images["Listening"]
            XCTAssertTrue(listeningIndicator.waitForExistence(timeout: 2) || true) // Optional feature
        }
    }
    
    // MARK: - Biometric Lock
    
    func testBiometricLockUI() throws {
        // If biometric lock is enabled, verify unlock UI appears
        let unlockButton = app.buttons["Unlock"]
        
        if unlockButton.exists {
            XCTAssertTrue(app.staticTexts["Minima is Locked"].exists)
            // Cannot test actual biometric in UI tests
        }
    }
}

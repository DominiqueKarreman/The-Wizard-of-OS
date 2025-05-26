import XCTest

final class The_Wizard_of_OSUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testSendPrompt() {
        let promptTextField = app.textFields["textFieldInput"]
        let sendButton = app.buttons["Send"]
        
        promptTextField.tap()
        promptTextField.typeText("Hello, Merlin!")
        
        XCTAssertEqual(promptTextField.value as? String, "Hello, Merlin!")
        
        sendButton.tap()
        
        let lastMessage = app.staticTexts["Hello, Merlin!"]
        XCTAssertTrue(lastMessage.exists, "The sent prompt should appear in the message list view")
    }
    func testOfflineButtonToggle() {
        let offlineButton = app.buttons["OfflineButton"]
        XCTAssertTrue(offlineButton.exists)
        
        // Initially, the button should contain "Online" text
        XCTAssertTrue(offlineButton.label.contains("Online"))
        
        // Tap the button to toggle the state to "Offline"
        offlineButton.tap()
        
        // Verify that the button label has changed to "Offline"
        XCTAssertTrue(offlineButton.label.contains("Offline"))
        
        // Tap the button again to toggle back to "Online"
        offlineButton.tap()
        
        // Verify that the button label has changed back to "Online"
        XCTAssertTrue(offlineButton.label.contains("Online"))
    }
    func testVideoModeToggle() {
        let videoModeElement = app.otherElements["VideoMode"]
        XCTAssertTrue(videoModeElement.exists, "The VideoMode button should exist.")
        
        let label = app.staticTexts["videoModeIdentifier"]
        XCTAssertTrue(label.exists, "The label inside VideoMode should exist.")

        // Initial check
        XCTAssertEqual(label.label, "Video mode", "The label should initially be 'Video mode'.")

        // Click to activate video mode
        videoModeElement.click()
        
        // You could add a delay here to wait for animation/state change if needed
        // sleep(1) or use expectation with a state change if available

        // Click again to deactivate video mode
        videoModeElement.click()
        
        // Final check: label still exists and shows correct text
        XCTAssertTrue(label.exists, "The label should still be visible after toggling.")
        XCTAssertEqual(label.label, "Video mode", "The label text should remain 'Video mode' after toggling.")
    }
    func testModelSelectionWithList() {
        let app = XCUIApplication()
        app.launch()

        // 🔹 Tap the model selection button to open the modal
        let modelSelectionButton = app.buttons["ModelSelectionButton"]
        XCTAssertTrue(modelSelectionButton.waitForExistence(timeout: 5), "Model selection button should exist")
        modelSelectionButton.tap() // Tap to open the modal

        // 🔹 Wait for the modal to appear
        let modalBackground = app.otherElements["ModelSelectionModalBackground"]
        XCTAssertTrue(modalBackground.waitForExistence(timeout: 5), "Model selection modal did not appear")

        // 🔹 Verify the list of models in the modal
        let llamaOption = app.staticTexts["llama3"]
        let deepseekOption = app.staticTexts["deepseek-r1"]
        XCTAssertTrue(llamaOption.waitForExistence(timeout: 5), "Model option 'llama3' should appear")
        XCTAssertTrue(deepseekOption.waitForExistence(timeout: 5), "Model option 'deepseek-r1' should appear")

        // 🔹 Tap the 'Select' button for the 'deepseek-r1' model
        let selectButton = app.buttons["SelectModelButton_deepseek-r1"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 5), "Select button for 'deepseek-r1' should exist")
        selectButton.tap()

        // 🔹 Verify the modal is dismissed
        XCTAssertFalse(modalBackground.exists, "Model selection modal should be dismissed")

        // 🔹 Verify the selected model is updated in the main view
        let modelSelectionButtonLabel = modelSelectionButton.label
        XCTAssertEqual(modelSelectionButtonLabel, "deepseek-r1", "The model selection should be updated to 'deepseek-r1'")
    }
}

   

//
//  The_Wizard_of_OSUITests.swift
//  The Wizard of OSUITests
//
//  Created by Dominique Karreman on 3/6/25.
//

import XCTest

final class The_Wizard_of_OSUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

import XCTest
import SwiftUI

class ContentViewTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        // Initialize the app instance before each test
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        // Clean up after each test
        app = nil
        super.tearDown()
    }
    
    func testSendPrompt() {
        // Given: The ContentView is loaded, and the user sees the prompt text field
        
        let promptTextField = app.textFields["textFieldInput"] // Assuming the text field has a placeholder of "Prompt:"
        let sendButton = app.buttons["Send"] // Assuming the send button has an accessible label "Send"
        
        // When: User enters a prompt and presses the send button
        promptTextField.tap()
        promptTextField.typeText("Hello, Merlin!")
        
        // Ensure the text was typed correctly
        XCTAssertEqual(promptTextField.value as? String, "Hello, Merlin!")
        
        sendButton.tap()
        
        // Then: Verify the prompt was sent and appears in the message list view
        let lastMessage = app.staticTexts["Hello, Merlin!"] // Replace with the actual expected message
        XCTAssertTrue(lastMessage.exists, "The sent prompt should appear in the message list view")
    }
    
}

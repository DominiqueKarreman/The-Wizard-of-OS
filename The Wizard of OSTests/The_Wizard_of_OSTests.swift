import XCTest
@testable import The_Wizard_of_OS

class StreamingAPIClientTests: XCTestCase {
    
    var streamingApiClient: StreamingAPIClient!
    var mockChatMessageVM: ChatMessageViewModel!
    var mockMessageListVM: ChatMessageListViewModel!
    
    override func setUp() {
        super.setUp()
        // Create mock ViewModel objects
        mockChatMessageVM = ChatMessageViewModel()
        mockMessageListVM = ChatMessageListViewModel(context: PersistenceController.shared.container.viewContext)
        
        // Initialize the StreamingAPIClient with mocks
        streamingApiClient = StreamingAPIClient(chatMessageVM: mockChatMessageVM, chatMessageListVM: mockMessageListVM, context: PersistenceController.shared.container.viewContext)
    }
    
    override func tearDown() {
        // Clean up after each test
        streamingApiClient = nil
        mockChatMessageVM = nil
        mockMessageListVM = nil
        super.tearDown()
    }
    
    func testStreamResponse_SuccessWithPrompt() {
        // Test for successful streaming response when providing a valid prompt
        
        // Prepare a prompt
        let prompt = "What is the weather today?"
        
        // Set expectations
        let expectation = self.expectation(description: "API response should be received")
        
        // Start the streaming
        streamingApiClient.streamResponse(for: prompt, image: nil)
        
        // Simulate API response and check if it triggers the update
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Print the content for debugging
            print(self.mockMessageListVM.tempAssistantMessage?.message.isEmpty ?? true, "empty or not", self.mockMessageListVM.tempAssistantMessage?.message)
            
            // Assert that the message is not empty
            XCTAssertFalse(self.mockMessageListVM.tempAssistantMessage?.message.isEmpty ?? true, "Expected tempAssistantMessage to not be empty")
            
            // Fulfill the expectation to let the test know it has completed
            expectation.fulfill()
        }
        
        // Wait for the expectation to be fulfilled
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
}

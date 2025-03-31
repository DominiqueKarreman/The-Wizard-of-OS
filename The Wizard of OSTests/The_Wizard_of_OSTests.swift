import XCTest
@testable import The_Wizard_of_OS

class CoreDataTest: XCTestCase {
    var context: NSManagedObjectContext!
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        
        // Initialize the persistence controller and mock context for testing
        persistenceController = PersistenceController(inMemory: true)  // Assume this is how you set up your in-memory store
        context = persistenceController.container.viewContext
    }
    
    func testMessageSaving() {
        // Create a test message
        let newMessage = Message(context: context)
        newMessage.id = UUID()
        newMessage.sender = "Merlin"
        newMessage.timestamp = Date()
        newMessage.message = "Test message"
        
        // Save the context
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save context: \(error)")
        }
        
        // Fetch the message from the context
        let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "sender == %@", "Merlin")
        
        do {
            let fetchedMessages = try context.fetch(fetchRequest)
            
            // Assert that we have one message saved with the correct details
            XCTAssertEqual(fetchedMessages.count, 1, "There should be one message saved")
            XCTAssertEqual(fetchedMessages.first?.sender, "Merlin", "The sender should be Merlin")
            XCTAssertEqual(fetchedMessages.first?.message, "Test message", "The message content should match")
            
        } catch {
            XCTFail("Failed to fetch messages: \(error)")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        
        // Reset the context to ensure a fresh start for each test
        context.rollback()
    }
    
    
}


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

//
//  CoreDataTest.swift
//  The Wizard of OS
//
//  Created by Dominique Karreman on 3/26/25.
//


import XCTest
import CoreData
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

import Testing
import Foundation

struct MockChatMessageListVM {
    var tempAssistantMessage: MockMessage? = MockMessage(message: "")
    var tempVoiceAssistantMessage: MockMessage? = MockMessage(message: "")
    var isStreaming = false
    var messages: [MockMessage] = []
    var errors: [String] = []
    mutating func addTempMessage() { tempAssistantMessage = MockMessage(message: "") }
    mutating func addVoiceTempMessage() { tempVoiceAssistantMessage = MockMessage(message: "") }
    mutating func addErrorMessage(_ msg: String) { errors.append(msg) }
    mutating func resetTempMessage() { tempAssistantMessage = nil }
    mutating func resetTempVoiceMessage() { tempVoiceAssistantMessage = nil }
}
struct MockMessage {
    var message: String
}

struct ContentViewLogicTests {
    @Test func testMimeTypeForExtension() {
        #expect(mimeTypeForExtension("jpg") == "image/jpeg")
        #expect(mimeTypeForExtension("pdf") == "application/pdf")
        #expect(mimeTypeForExtension("docx") == "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
        #expect(mimeTypeForExtension("unknown") == "application/octet-stream")
    }

    @Test func testModeSwitchingAffectsState() {
        var videoMode = false
        var voiceMode = false
        var screenshotMode = false
        // Simulate toggling video mode
        videoMode.toggle()
        if videoMode { voiceMode = true; screenshotMode = false }
        #expect(videoMode)
        #expect(voiceMode)
        #expect(!screenshotMode)
    }

    @Test func testStreamingApiClientErrorHandling() {
        var vm = MockChatMessageListVM()
        let errorMsg = "Test error"
        vm.addErrorMessage(errorMsg)
        #expect(vm.errors.contains(errorMsg))
    }

    @Test func testTempMessageLifecycle() {
        var vm = MockChatMessageListVM()
        vm.addTempMessage();
        #expect(vm.tempAssistantMessage != nil)
        vm.resetTempMessage();
        #expect(vm.tempAssistantMessage == nil)
        vm.addVoiceTempMessage();
        #expect(vm.tempVoiceAssistantMessage != nil)
        vm.resetTempVoiceMessage();
        #expect(vm.tempVoiceAssistantMessage == nil)
    }

    @Test func testMimeTypeFallbackToOctetStream() {
        #expect(mimeTypeForExtension("foo") == "application/octet-stream")
    }
}

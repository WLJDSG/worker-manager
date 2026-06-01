import XCTest
@testable import ExecutionFeature
@testable import Core

@MainActor
final class ExecutionViewModelTests: XCTestCase {
    func testSendChatMessageRequiresSelectedModel() async throws {
        let state = AppState(store: ProviderStore(configURL: temporaryConfigURL()))
        let viewModel = ExecutionViewModel(
            appState: state,
            credentialStore: MemoryCredentialStore(),
            chatService: FakeChatTestingService(response: "Hi")
        )
        viewModel.chatDraft = "Hello"

        await viewModel.sendChatMessage()

        XCTAssertEqual(viewModel.chatMessages, [])
        XCTAssertEqual(state.lastStatusKind, .failure)
    }

    func testSendChatMessageRequiresNonEmptyDraft() async throws {
        let provider = makeProvider()
        let model = makeModel(providerID: provider.id)
        let state = AppState(store: ProviderStore(configURL: temporaryConfigURL()))
        state.providers = [provider]
        state.models = [model]
        state.selectedModelName = model.name
        let viewModel = ExecutionViewModel(
            appState: state,
            credentialStore: MemoryCredentialStore(),
            chatService: FakeChatTestingService(response: "Hi")
        )
        viewModel.chatDraft = "   "

        await viewModel.sendChatMessage()

        XCTAssertEqual(viewModel.chatMessages, [])
        XCTAssertEqual(state.lastStatusKind, .failure)
    }

    func testSendChatMessageAppendsUserAndAssistantMessages() async throws {
        let provider = makeProvider()
        let model = makeModel(providerID: provider.id)
        let state = AppState(store: ProviderStore(configURL: temporaryConfigURL()))
        state.providers = [provider]
        state.models = [model]
        state.selectedModelName = model.name
        let service = FakeChatTestingService(response: "你好，我在线。")
        let viewModel = ExecutionViewModel(
            appState: state,
            credentialStore: MemoryCredentialStore(),
            chatService: service
        )
        viewModel.chatDraft = "你能收到吗？"

        await viewModel.sendChatMessage()

        XCTAssertEqual(viewModel.chatDraft, "")
        XCTAssertEqual(viewModel.chatMessages.map(\.role), [.user, .assistant])
        XCTAssertEqual(viewModel.chatMessages.map(\.content), ["你能收到吗？", "你好，我在线。"])
        XCTAssertEqual(service.lastMessages?.map(\.content), ["你能收到吗？"])
        XCTAssertEqual(state.lastStatusKind, .success)
    }

    func testClearConversationRemovesHistoryAndDraft() {
        let state = AppState(store: ProviderStore(configURL: temporaryConfigURL()))
        let viewModel = ExecutionViewModel(appState: state, credentialStore: MemoryCredentialStore())
        viewModel.chatDraft = "Hello"
        viewModel.chatMessages = [
            ChatMessage(role: .user, content: "Hello"),
            ChatMessage(role: .assistant, content: "Hi")
        ]

        viewModel.clearConversation()

        XCTAssertEqual(viewModel.chatDraft, "")
        XCTAssertEqual(viewModel.chatMessages, [])
    }

    func testClearPreviewOnlyClearsGeneratedPatchPreview() {
        let state = AppState(store: ProviderStore(configURL: temporaryConfigURL()))
        let viewModel = ExecutionViewModel(appState: state, credentialStore: MemoryCredentialStore())
        viewModel.delegationInstruction = "Keep this instruction"
        viewModel.generatedPatchPreview = "diff --git a/file b/file"

        viewModel.clearGeneratedPreview()

        XCTAssertEqual(viewModel.delegationInstruction, "Keep this instruction")
        XCTAssertEqual(viewModel.generatedPatchPreview, "")
    }

    private func temporaryConfigURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("config.json")
    }

    private func makeProvider() -> ModelProvider {
        ModelProvider(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "DeepSeek",
            kind: .deepSeek,
            baseURL: URL(string: "https://api.deepseek.com")!,
            apiKeyReference: "provider.deepseek"
        )
    }

    private func makeModel(providerID: UUID) -> WorkerModel {
        WorkerModel(
            providerID: providerID,
            name: "deepseek-chat",
            displayName: "DeepSeek Chat",
            isCustom: true
        )
    }
}

private final class FakeChatTestingService: ChatTestingService, @unchecked Sendable {
    private let response: String
    private(set) var lastMessages: [ChatMessage]?

    init(response: String) {
        self.response = response
    }

    func sendChat(
        messages: [ChatMessage],
        provider: ModelProvider,
        model: WorkerModel
    ) async throws -> String {
        lastMessages = messages
        return response
    }
}

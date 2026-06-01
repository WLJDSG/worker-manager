import XCTest
@testable import ProviderFeature
@testable import Core

@MainActor
final class ProviderViewModelTests: XCTestCase {
    func testDeleteSelectedProviderRemovesProviderModelsAndMovesSelection() async throws {
        let providerA = makeProvider(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, name: "DeepSeek")
        let providerB = makeProvider(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, name: "OpenAI")
        let modelA = makeModel(providerID: providerA.id, name: "deepseek-chat")
        let modelB = makeModel(providerID: providerB.id, name: "gpt-4.1")
        let (viewModel, appState, store, _) = try await makeViewModel(
            providers: [providerA, providerB],
            models: [modelA, modelB]
        )
        await appState.load()
        appState.selectedProviderID = providerA.id
        appState.selectedModelName = modelA.name

        await viewModel.deleteSelectedProvider()

        XCTAssertEqual(appState.providers, [providerB])
        XCTAssertEqual(appState.models, [modelB])
        XCTAssertEqual(appState.selectedProviderID, providerB.id)
        XCTAssertEqual(appState.selectedModelName, modelB.name)

        let saved = try await store.load()
        XCTAssertEqual(saved.providers, [providerB])
        XCTAssertEqual(saved.models, [modelB])
    }

    func testSaveSelectedProviderEditsProviderAndOptionalAPIKey() async throws {
        let provider = makeProvider(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, name: "DeepSeek")
        let (viewModel, appState, store, credentials) = try await makeViewModel(providers: [provider])
        try await credentials.saveAPIKey("old-key", for: provider.apiKeyReference)
        await appState.load()
        appState.selectedProviderID = provider.id
        viewModel.syncEditFieldsWithSelection()
        viewModel.editProviderName = "DeepSeek Updated"
        viewModel.editProviderKind = .openAICompatible
        viewModel.editProviderBaseURL = "https://example.com/v1"
        viewModel.editProviderAPIKey = "new-key"

        await viewModel.saveSelectedProviderEdits()

        let updated = try XCTUnwrap(appState.providers.first)
        XCTAssertEqual(updated.id, provider.id)
        XCTAssertEqual(updated.name, "DeepSeek Updated")
        XCTAssertEqual(updated.kind, .openAICompatible)
        XCTAssertEqual(updated.baseURL, URL(string: "https://example.com/v1"))
        XCTAssertEqual(updated.apiKeyReference, provider.apiKeyReference)
        let savedAPIKey = try await credentials.apiKey(for: provider.apiKeyReference)
        XCTAssertEqual(savedAPIKey, "new-key")

        let saved = try await store.load()
        XCTAssertEqual(saved.providers.first?.name, "DeepSeek Updated")
    }

    func testAddProviderValidatesNameURLAndAPIKey() async throws {
        let (viewModel, appState, store, _) = try await makeViewModel()
        viewModel.newProviderName = "   "
        viewModel.newProviderBaseURL = "not a url"
        viewModel.newProviderAPIKey = ""

        await viewModel.addProvider()

        XCTAssertEqual(appState.providers, [])
        XCTAssertEqual(appState.lastStatusKind, .failure)
        let saved = try await store.load()
        XCTAssertEqual(saved.providers, [])
    }

    private func makeViewModel(
        providers: [ModelProvider] = [],
        models: [WorkerModel] = []
    ) async throws -> (ProviderViewModel, AppState, ProviderStore, MemoryCredentialStore) {
        let store = ProviderStore(configURL: temporaryConfigURL())
        let credentials = MemoryCredentialStore()
        try await store.save(WorkerManagerConfiguration(providers: providers, models: models))
        let state = AppState(store: store)
        return (
            ProviderViewModel(appState: state, credentialStore: credentials),
            state,
            store,
            credentials
        )
    }

    private func makeProvider(
        id: UUID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        name: String = "DeepSeek"
    ) -> ModelProvider {
        ModelProvider(
            id: id,
            name: name,
            kind: .deepSeek,
            baseURL: URL(string: "https://api.deepseek.com")!,
            apiKeyReference: "provider.\(id.uuidString.lowercased())"
        )
    }

    private func makeModel(providerID: UUID, name: String) -> WorkerModel {
        WorkerModel(
            providerID: providerID,
            name: name,
            displayName: name,
            isCustom: true
        )
    }

    private func temporaryConfigURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("config.json")
    }
}
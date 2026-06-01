import XCTest
@testable import ModelFeature
@testable import Core

@MainActor
final class ModelViewModelTests: XCTestCase {
    func testDeleteModelClearsSelectedModelWhenDeleted() async throws {
        let provider = makeProvider()
        let modelA = makeModel(providerID: provider.id, name: "deepseek-chat")
        let modelB = makeModel(providerID: provider.id, name: "deepseek-reasoner")
        let (viewModel, appState, store) = try await makeViewModel(
            providers: [provider],
            models: [modelA, modelB]
        )
        await appState.load()
        appState.selectedProviderID = provider.id
        appState.selectedModelName = modelA.name

        await viewModel.deleteModel(modelA)

        XCTAssertEqual(appState.models, [modelB])
        XCTAssertEqual(appState.selectedModelName, modelB.name)

        let saved = try await store.load()
        XCTAssertEqual(saved.models, [modelB])
    }

    private func makeViewModel(
        providers: [ModelProvider] = [],
        models: [WorkerModel] = []
    ) async throws -> (ModelViewModel, AppState, ProviderStore) {
        let store = ProviderStore(configURL: temporaryConfigURL())
        let credentials = MemoryCredentialStore()
        try await store.save(WorkerManagerConfiguration(providers: providers, models: models))
        let state = AppState(store: store)
        return (
            ModelViewModel(appState: state, credentialStore: credentials),
            state,
            store
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
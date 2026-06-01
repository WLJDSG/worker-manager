import XCTest
@testable import Core

final class ProviderStoreTests: XCTestCase {
    func testSaveAndLoadConfiguration() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ProviderStore(configURL: directory.appendingPathComponent("config.json"))

        let provider = ModelProvider(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "DeepSeek",
            kind: .deepSeek,
            baseURL: URL(string: "https://api.deepseek.com")!,
            apiKeyReference: "provider.deepseek"
        )
        let model = WorkerModel(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            providerID: provider.id,
            name: "deepseek-v4-pro",
            displayName: "DeepSeek V4 Pro",
            contextWindow: 128_000,
            supportsStreaming: true,
            supportsToolUse: false,
            isCustom: true
        )

        try await store.save(WorkerManagerConfiguration(providers: [provider], models: [model]))
        let loaded = try await store.load()

        XCTAssertEqual(loaded.providers, [provider])
        XCTAssertEqual(loaded.models, [model])
    }

    func testLoadMissingFileReturnsEmptyConfiguration() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ProviderStore(configURL: directory.appendingPathComponent("missing.json"))

        let loaded = try await store.load()

        XCTAssertEqual(loaded.providers, [])
        XCTAssertEqual(loaded.models, [])
    }
}
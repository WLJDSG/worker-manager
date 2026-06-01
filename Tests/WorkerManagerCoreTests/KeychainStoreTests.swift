import XCTest
@testable import WorkerManagerCore

final class KeychainStoreTests: XCTestCase {
    func testMemoryCredentialStoreRoundTrip() async throws {
        let store = MemoryCredentialStore()

        try await store.saveAPIKey("sk-test", for: "provider.deepseek")
        let loaded = try await store.apiKey(for: "provider.deepseek")

        XCTAssertEqual(loaded, "sk-test")
    }

    func testMemoryCredentialStoreReturnsNilForMissingKey() async throws {
        let store = MemoryCredentialStore()

        let loaded = try await store.apiKey(for: "provider.unknown")

        XCTAssertNil(loaded)
    }
}

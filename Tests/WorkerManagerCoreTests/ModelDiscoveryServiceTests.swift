import XCTest
@testable import WorkerManagerCore

final class ModelDiscoveryServiceTests: XCTestCase {
    func testDiscoversOpenAICompatibleModels() async throws {
        let providerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let provider = ModelProvider(
            id: providerID,
            name: "DeepSeek",
            kind: .deepSeek,
            baseURL: URL(string: "https://api.deepseek.com")!,
            apiKeyReference: "provider.deepseek"
        )
        let http = MockHTTPClient(data: """
        {
          "data": [
            { "id": "deepseek-chat" },
            { "id": "deepseek-reasoner" }
          ]
        }
        """.data(using: .utf8)!)
        let credentials = MemoryCredentialStore()
        try await credentials.saveAPIKey("sk-test", for: "provider.deepseek")
        let service = ModelDiscoveryService(httpClient: http, credentialStore: credentials)

        let models = try await service.discoverModels(for: provider)

        XCTAssertEqual(models.map(\.name), ["deepseek-chat", "deepseek-reasoner"])
        XCTAssertEqual(models.map(\.providerID), [providerID, providerID])
        XCTAssertTrue(models.allSatisfy { !$0.isCustom })
        XCTAssertEqual(http.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test")
    }

    func testMissingAPIKeyThrows() async throws {
        let provider = ModelProvider(
            name: "DeepSeek",
            kind: .deepSeek,
            baseURL: URL(string: "https://api.deepseek.com")!,
            apiKeyReference: "provider.deepseek"
        )
        let service = ModelDiscoveryService(
            httpClient: MockHTTPClient(data: Data()),
            credentialStore: MemoryCredentialStore()
        )

        do {
            _ = try await service.discoverModels(for: provider)
            XCTFail("Expected missing API key error")
        } catch WorkerManagerError.missingAPIKey(let reference) {
            XCTAssertEqual(reference, "provider.deepseek")
        }
    }
}

private final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    private let data: Data
    private(set) var lastRequest: URLRequest?

    init(data: Data) {
        self.data = data
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lastRequest = request
        return (
            data,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
        )
    }
}

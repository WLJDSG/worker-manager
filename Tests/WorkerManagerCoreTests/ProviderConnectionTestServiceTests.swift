import XCTest
@testable import WorkerManagerCore

final class ProviderConnectionTestServiceTests: XCTestCase {
    func testConnectionTestSucceedsWhenModelsEndpointResponds() async throws {
        let provider = ModelProvider(
            name: "DeepSeek",
            kind: .deepSeek,
            baseURL: URL(string: "https://api.deepseek.com")!,
            apiKeyReference: "provider.deepseek"
        )
        let http = ConnectionMockHTTPClient(
            data: """
            {
              "data": [
                { "id": "deepseek-chat" },
                { "id": "deepseek-reasoner" }
              ]
            }
            """.data(using: .utf8)!,
            statusCode: 200
        )
        let credentials = MemoryCredentialStore()
        try await credentials.saveAPIKey("sk-test", for: "provider.deepseek")
        let service = ProviderConnectionTestService(
            httpClient: http,
            credentialStore: credentials
        )

        let result = try await service.testConnection(for: provider)

        XCTAssertEqual(result.providerName, "DeepSeek")
        XCTAssertEqual(result.discoveredModelCount, 2)
        XCTAssertEqual(http.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test")
        XCTAssertEqual(http.lastRequest?.httpMethod, "GET")
    }

    func testConnectionTestThrowsWhenAPIKeyIsMissing() async throws {
        let provider = ModelProvider(
            name: "DeepSeek",
            kind: .deepSeek,
            baseURL: URL(string: "https://api.deepseek.com")!,
            apiKeyReference: "provider.deepseek"
        )
        let service = ProviderConnectionTestService(
            httpClient: ConnectionMockHTTPClient(data: Data(), statusCode: 200),
            credentialStore: MemoryCredentialStore()
        )

        do {
            _ = try await service.testConnection(for: provider)
            XCTFail("Expected missing API key")
        } catch WorkerManagerError.missingAPIKey(let reference) {
            XCTAssertEqual(reference, "provider.deepseek")
        }
    }

    func testConnectionTestThrowsOnNonSuccessResponse() async throws {
        let provider = ModelProvider(
            name: "DeepSeek",
            kind: .deepSeek,
            baseURL: URL(string: "https://api.deepseek.com")!,
            apiKeyReference: "provider.deepseek"
        )
        let credentials = MemoryCredentialStore()
        try await credentials.saveAPIKey("sk-test", for: "provider.deepseek")
        let service = ProviderConnectionTestService(
            httpClient: ConnectionMockHTTPClient(data: Data(), statusCode: 401),
            credentialStore: credentials
        )

        do {
            _ = try await service.testConnection(for: provider)
            XCTFail("Expected invalid response")
        } catch WorkerManagerError.invalidResponse(let message) {
            XCTAssertTrue(message.contains("HTTP 401"))
        }
    }
}

private final class ConnectionMockHTTPClient: HTTPClient, @unchecked Sendable {
    private let data: Data
    private let statusCode: Int
    private(set) var lastRequest: URLRequest?

    init(data: Data, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lastRequest = request
        return (
            data,
            HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
        )
    }
}

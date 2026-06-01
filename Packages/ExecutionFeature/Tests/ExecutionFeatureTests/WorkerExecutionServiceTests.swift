import XCTest
@testable import ExecutionFeature
@testable import Core

final class WorkerExecutionServiceTests: XCTestCase {
    func testRunsTaskAgainstOpenAICompatibleProvider() async throws {
        let providerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let provider = ModelProvider(
            id: providerID,
            name: "DeepSeek",
            kind: .deepSeek,
            baseURL: URL(string: "https://api.deepseek.com")!,
            apiKeyReference: "provider.deepseek"
        )
        let model = WorkerModel(
            providerID: providerID,
            name: "deepseek-v4-pro",
            displayName: "DeepSeek V4 Pro",
            isCustom: true
        )
        let http = MockExecutionHTTPClient(data: """
        {
          "choices": [
            {
              "message": {
                "content": "```diff\\n--- a/App.swift\\n+++ b/App.swift\\n@@ -1 +1 @@\\n-print(\\"old\\")\\n+print(\\"new\\")\\n```"
              }
            }
          ]
        }
        """.data(using: .utf8)!)
        let credentials = MemoryCredentialStore()
        try await credentials.saveAPIKey("sk-test", for: "provider.deepseek")
        let service = WorkerExecutionService(httpClient: http, credentialStore: credentials)

        let result = try await service.run(
            task: WorkerTask(
                modelName: "deepseek-v4-pro",
                instruction: "Change old to new",
                workspacePath: "/tmp/example"
            ),
            provider: provider,
            model: model
        )

        XCTAssertTrue(result.patchText.contains("+print(\"new\")"))
        XCTAssertEqual(result.modelName, "deepseek-v4-pro")
        XCTAssertEqual(http.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test")
    }

    func testSendsChatMessagesAgainstOpenAICompatibleProvider() async throws {
        let providerID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let provider = ModelProvider(
            id: providerID,
            name: "DeepSeek",
            kind: .deepSeek,
            baseURL: URL(string: "https://api.deepseek.com")!,
            apiKeyReference: "provider.deepseek"
        )
        let model = WorkerModel(
            providerID: providerID,
            name: "deepseek-chat",
            displayName: "DeepSeek Chat",
            isCustom: true
        )
        let http = MockExecutionHTTPClient(data: """
        {
          "choices": [
            {
              "message": {
                "content": "Hi there"
              }
            }
          ]
        }
        """.data(using: .utf8)!)
        let credentials = MemoryCredentialStore()
        try await credentials.saveAPIKey("sk-test", for: "provider.deepseek")
        let service = WorkerExecutionService(httpClient: http, credentialStore: credentials)

        let response = try await service.sendChat(
            messages: [ChatMessage(role: .user, content: "Hello")],
            provider: provider,
            model: model
        )

        XCTAssertEqual(response, "Hi there")
        XCTAssertEqual(http.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test")
        let body = String(data: http.lastRequest?.httpBody ?? Data(), encoding: .utf8)
        XCTAssertTrue(body?.contains("\"model\":\"deepseek-chat\"") == true)
        XCTAssertTrue(body?.contains("\"content\":\"Hello\"") == true)
    }
}

private final class MockExecutionHTTPClient: HTTPClient, @unchecked Sendable {
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

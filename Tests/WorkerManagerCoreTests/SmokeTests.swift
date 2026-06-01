import XCTest
@testable import WorkerManagerCore

final class SmokeTests: XCTestCase {
    func testProviderCanBeCreated() throws {
        let provider = ModelProvider(
            name: "DeepSeek",
            kind: .deepSeek,
            baseURL: try XCTUnwrap(URL(string: "https://api.deepseek.com")),
            apiKeyReference: "provider.deepseek"
        )

        XCTAssertEqual(provider.name, "DeepSeek")
        XCTAssertTrue(provider.isEnabled)
    }
}

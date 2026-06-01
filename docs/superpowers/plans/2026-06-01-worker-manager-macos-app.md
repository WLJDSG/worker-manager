# Worker Manager macOS App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS app that manages model providers and worker models, fetches provider-supported models, and exposes a CLI bridge so Codex can delegate implementation work to configured models while GPT keeps planning and review authority.

**Architecture:** Use a Swift Package containing a SwiftUI macOS app, a shared core library, and a CLI executable. The app handles provider configuration, Keychain-backed API keys, model discovery, custom model registration, and a guided delegation preview; the CLI reads the same config and can be called by Codex workflows to ask a worker model to generate code patches.

**Tech Stack:** Swift 5.10+, SwiftUI, Swift Package Manager, XCTest, URLSession, Security.framework Keychain APIs, JSON file persistence, async/await.

---

## Scope Notes

This plan intentionally builds the local manager and delegation bridge. It does not patch Codex internals. After implementation, Codex can delegate by invoking `worker-manager-cli run --model deepseek-v4-pro --task-file task.md --workspace /path/to/project`, then GPT reviews the output before writing or applying changes.

Current repository state on 2026-06-01: `/Users/wenlanjun/办公/workspace/worker-manager` is empty and is not a git repository. Task 1 initializes the Swift package and git repository.

## File Structure

- Create `Package.swift`: defines the macOS app executable, CLI executable, shared library, and test target.
- Create `Sources/WorkerManagerCore/Domain.swift`: core domain models for providers, models, credentials, requests, and generated artifacts.
- Create `Sources/WorkerManagerCore/ProviderCatalog.swift`: provider templates and supported API styles.
- Create `Sources/WorkerManagerCore/ProviderStore.swift`: JSON-backed persistence for providers and models.
- Create `Sources/WorkerManagerCore/KeychainStore.swift`: Keychain API-key storage.
- Create `Sources/WorkerManagerCore/ModelDiscoveryService.swift`: fetches provider models from OpenAI-compatible APIs and provider-specific endpoints.
- Create `Sources/WorkerManagerCore/WorkerExecutionService.swift`: sends implementation tasks to configured worker models and returns patch text plus metadata.
- Create `Sources/WorkerManagerCLI/main.swift`: command-line bridge for Codex.
- Create `Sources/WorkerManagerApp/WorkerManagerApp.swift`: SwiftUI app entry point.
- Create `Sources/WorkerManagerApp/AppViewModel.swift`: UI state orchestration.
- Create `Sources/WorkerManagerApp/ContentView.swift`: provider/model management UI.
- Create `Tests/WorkerManagerCoreTests/ProviderStoreTests.swift`: persistence tests.
- Create `Tests/WorkerManagerCoreTests/ModelDiscoveryServiceTests.swift`: model discovery tests with mocked HTTP.
- Create `Tests/WorkerManagerCoreTests/WorkerExecutionServiceTests.swift`: worker execution request/response tests.
- Create `Tests/WorkerManagerCLITests/WorkerManagerCLITests.swift`: CLI smoke tests.
- Create `README.md`: local setup and Codex delegation usage.

---

### Task 1: Initialize Swift Package and Repository

**Files:**
- Create: `Package.swift`
- Create: `Sources/WorkerManagerCore/Domain.swift`
- Create: `Sources/WorkerManagerApp/WorkerManagerApp.swift`
- Create: `Sources/WorkerManagerCLI/main.swift`
- Create: `Tests/WorkerManagerCoreTests/SmokeTests.swift`
- Create: `.gitignore`
- Create: `README.md`

- [ ] **Step 1: Initialize git repository**

Run:

```bash
git init
```

Expected: command prints `Initialized empty Git repository`.

- [ ] **Step 2: Create `.gitignore`**

Create `.gitignore`:

```gitignore
.build/
.swiftpm/
DerivedData/
*.xcuserstate
.DS_Store
worker-manager.config.json
```

- [ ] **Step 3: Create `Package.swift`**

Create `Package.swift`:

```swift
// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WorkerManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "WorkerManagerCore", targets: ["WorkerManagerCore"]),
        .executable(name: "WorkerManagerApp", targets: ["WorkerManagerApp"]),
        .executable(name: "worker-manager-cli", targets: ["WorkerManagerCLI"])
    ],
    targets: [
        .target(name: "WorkerManagerCore"),
        .executableTarget(
            name: "WorkerManagerApp",
            dependencies: ["WorkerManagerCore"]
        ),
        .executableTarget(
            name: "WorkerManagerCLI",
            dependencies: ["WorkerManagerCore"]
        ),
        .testTarget(
            name: "WorkerManagerCoreTests",
            dependencies: ["WorkerManagerCore"]
        ),
        .testTarget(
            name: "WorkerManagerCLITests",
            dependencies: ["WorkerManagerCore"]
        )
    ]
)
```

- [ ] **Step 4: Create minimal domain model**

Create `Sources/WorkerManagerCore/Domain.swift`:

```swift
import Foundation

public enum ProviderKind: String, Codable, CaseIterable, Sendable {
    case openAICompatible
    case deepSeek
    case anthropic
    case custom
}

public struct ModelProvider: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var kind: ProviderKind
    public var baseURL: URL
    public var apiKeyReference: String
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        kind: ProviderKind,
        baseURL: URL,
        apiKeyReference: String,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.baseURL = baseURL
        self.apiKeyReference = apiKeyReference
        self.isEnabled = isEnabled
    }
}

public struct WorkerModel: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var providerID: UUID
    public var name: String
    public var displayName: String
    public var contextWindow: Int?
    public var supportsStreaming: Bool
    public var supportsToolUse: Bool
    public var isCustom: Bool

    public init(
        id: UUID = UUID(),
        providerID: UUID,
        name: String,
        displayName: String,
        contextWindow: Int? = nil,
        supportsStreaming: Bool = true,
        supportsToolUse: Bool = false,
        isCustom: Bool = false
    ) {
        self.id = id
        self.providerID = providerID
        self.name = name
        self.displayName = displayName
        self.contextWindow = contextWindow
        self.supportsStreaming = supportsStreaming
        self.supportsToolUse = supportsToolUse
        self.isCustom = isCustom
    }
}
```

- [ ] **Step 5: Create app entry point**

Create `Sources/WorkerManagerApp/WorkerManagerApp.swift`:

```swift
import SwiftUI

@main
struct WorkerManagerApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Worker Manager")
                .frame(minWidth: 900, minHeight: 620)
        }
    }
}
```

- [ ] **Step 6: Create CLI entry point**

Create `Sources/WorkerManagerCLI/main.swift`:

```swift
import Foundation

@main
struct WorkerManagerCLI {
    static func main() {
        print("worker-manager-cli")
    }
}
```

- [ ] **Step 7: Create smoke test**

Create `Tests/WorkerManagerCoreTests/SmokeTests.swift`:

```swift
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
```

- [ ] **Step 8: Create README**

Create `README.md`:

```markdown
# Worker Manager

Worker Manager is a macOS app and CLI bridge for configuring model providers and worker models. Codex can use the CLI bridge to delegate implementation tasks to configured models while GPT keeps planning, review, and final file-write decisions.

## Build

```bash
swift build
swift test
```

## Run

```bash
swift run WorkerManagerApp
swift run worker-manager-cli
```
```

- [ ] **Step 9: Run tests**

Run:

```bash
swift test
```

Expected: tests pass with `Executed 1 test`.

- [ ] **Step 10: Commit**

Run:

```bash
git add .gitignore Package.swift README.md Sources Tests
git commit -m "chore: initialize worker manager swift package"
```

Expected: commit succeeds.

---

### Task 2: Add Provider Catalog and Persistence

**Files:**
- Modify: `Sources/WorkerManagerCore/Domain.swift`
- Create: `Sources/WorkerManagerCore/ProviderCatalog.swift`
- Create: `Sources/WorkerManagerCore/ProviderStore.swift`
- Create: `Tests/WorkerManagerCoreTests/ProviderStoreTests.swift`

- [ ] **Step 1: Write failing provider store tests**

Create `Tests/WorkerManagerCoreTests/ProviderStoreTests.swift`:

```swift
import XCTest
@testable import WorkerManagerCore

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
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter ProviderStoreTests
```

Expected: FAIL with missing `ProviderStore` and `WorkerManagerConfiguration`.

- [ ] **Step 3: Extend `Domain.swift`**

Append to `Sources/WorkerManagerCore/Domain.swift`:

```swift
public struct WorkerManagerConfiguration: Codable, Equatable, Sendable {
    public var providers: [ModelProvider]
    public var models: [WorkerModel]

    public init(providers: [ModelProvider] = [], models: [WorkerModel] = []) {
        self.providers = providers
        self.models = models
    }
}

public enum WorkerManagerError: Error, LocalizedError, Equatable {
    case providerNotFound(UUID)
    case modelNotFound(String)
    case invalidResponse(String)
    case missingAPIKey(String)

    public var errorDescription: String? {
        switch self {
        case .providerNotFound(let id):
            return "Provider not found: \(id.uuidString)"
        case .modelNotFound(let name):
            return "Model not found: \(name)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .missingAPIKey(let reference):
            return "Missing API key for \(reference)"
        }
    }
}
```

- [ ] **Step 4: Create provider catalog**

Create `Sources/WorkerManagerCore/ProviderCatalog.swift`:

```swift
import Foundation

public struct ProviderTemplate: Identifiable, Equatable, Sendable {
    public var id: ProviderKind { kind }
    public let kind: ProviderKind
    public let name: String
    public let defaultBaseURL: URL
    public let modelsPath: String
    public let chatCompletionsPath: String

    public init(
        kind: ProviderKind,
        name: String,
        defaultBaseURL: URL,
        modelsPath: String = "/v1/models",
        chatCompletionsPath: String = "/v1/chat/completions"
    ) {
        self.kind = kind
        self.name = name
        self.defaultBaseURL = defaultBaseURL
        self.modelsPath = modelsPath
        self.chatCompletionsPath = chatCompletionsPath
    }
}

public enum ProviderCatalog {
    public static let templates: [ProviderTemplate] = [
        ProviderTemplate(
            kind: .deepSeek,
            name: "DeepSeek",
            defaultBaseURL: URL(string: "https://api.deepseek.com")!
        ),
        ProviderTemplate(
            kind: .openAICompatible,
            name: "OpenAI Compatible",
            defaultBaseURL: URL(string: "https://api.openai.com")!
        ),
        ProviderTemplate(
            kind: .anthropic,
            name: "Anthropic",
            defaultBaseURL: URL(string: "https://api.anthropic.com")!,
            modelsPath: "/v1/models",
            chatCompletionsPath: "/v1/messages"
        )
    ]

    public static func template(for kind: ProviderKind) -> ProviderTemplate? {
        templates.first { $0.kind == kind }
    }
}
```

- [ ] **Step 5: Create provider store**

Create `Sources/WorkerManagerCore/ProviderStore.swift`:

```swift
import Foundation

public actor ProviderStore {
    private let configURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(configURL: URL = ProviderStore.defaultConfigURL()) {
        self.configURL = configURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func load() async throws -> WorkerManagerConfiguration {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return WorkerManagerConfiguration()
        }

        let data = try Data(contentsOf: configURL)
        return try decoder.decode(WorkerManagerConfiguration.self, from: data)
    }

    public func save(_ configuration: WorkerManagerConfiguration) async throws {
        let directory = configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(configuration)
        try data.write(to: configURL, options: .atomic)
    }

    public static func defaultConfigURL() -> URL {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".worker-manager", isDirectory: true)
        return base.appendingPathComponent("config.json")
    }
}
```

- [ ] **Step 6: Run tests**

Run:

```bash
swift test --filter ProviderStoreTests
```

Expected: PASS.

- [ ] **Step 7: Commit**

Run:

```bash
git add Sources/WorkerManagerCore Tests/WorkerManagerCoreTests
git commit -m "feat: persist providers and worker models"
```

Expected: commit succeeds.

---

### Task 3: Add Keychain-backed API Key Storage

**Files:**
- Create: `Sources/WorkerManagerCore/KeychainStore.swift`
- Create: `Tests/WorkerManagerCoreTests/KeychainStoreTests.swift`

- [ ] **Step 1: Write protocol-first tests**

Create `Tests/WorkerManagerCoreTests/KeychainStoreTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter KeychainStoreTests
```

Expected: FAIL with missing `MemoryCredentialStore`.

- [ ] **Step 3: Create credential stores**

Create `Sources/WorkerManagerCore/KeychainStore.swift`:

```swift
import Foundation
import Security

public protocol CredentialStore: Sendable {
    func saveAPIKey(_ apiKey: String, for reference: String) async throws
    func apiKey(for reference: String) async throws -> String?
    func deleteAPIKey(for reference: String) async throws
}

public actor MemoryCredentialStore: CredentialStore {
    private var values: [String: String] = [:]

    public init() {}

    public func saveAPIKey(_ apiKey: String, for reference: String) async throws {
        values[reference] = apiKey
    }

    public func apiKey(for reference: String) async throws -> String? {
        values[reference]
    }

    public func deleteAPIKey(for reference: String) async throws {
        values.removeValue(forKey: reference)
    }
}

public struct KeychainCredentialStore: CredentialStore {
    private let service: String

    public init(service: String = "com.worker-manager.credentials") {
        self.service = service
    }

    public func saveAPIKey(_ apiKey: String, for reference: String) async throws {
        let data = Data(apiKey.utf8)
        let query = baseQuery(reference: reference)
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw WorkerManagerError.invalidResponse("Keychain save failed with status \(status)")
        }
    }

    public func apiKey(for reference: String) async throws -> String? {
        var query = baseQuery(reference: reference)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw WorkerManagerError.invalidResponse("Keychain read failed with status \(status)")
        }
        return String(data: data, encoding: .utf8)
    }

    public func deleteAPIKey(for reference: String) async throws {
        let status = SecItemDelete(baseQuery(reference: reference) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw WorkerManagerError.invalidResponse("Keychain delete failed with status \(status)")
        }
    }

    private func baseQuery(reference: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: reference
        ]
    }
}
```

- [ ] **Step 4: Run tests**

Run:

```bash
swift test --filter KeychainStoreTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add Sources/WorkerManagerCore/KeychainStore.swift Tests/WorkerManagerCoreTests/KeychainStoreTests.swift
git commit -m "feat: store provider api keys securely"
```

Expected: commit succeeds.

---

### Task 4: Implement Model Discovery

**Files:**
- Modify: `Sources/WorkerManagerCore/Domain.swift`
- Create: `Sources/WorkerManagerCore/HTTPClient.swift`
- Create: `Sources/WorkerManagerCore/ModelDiscoveryService.swift`
- Create: `Tests/WorkerManagerCoreTests/ModelDiscoveryServiceTests.swift`

- [ ] **Step 1: Write failing model discovery test**

Create `Tests/WorkerManagerCoreTests/ModelDiscoveryServiceTests.swift`:

```swift
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

        XCTAssertEqual(models.map(\\.name), ["deepseek-chat", "deepseek-reasoner"])
        XCTAssertEqual(models.map(\\.providerID), [providerID, providerID])
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

private final class MockHTTPClient: HTTPClient {
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
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter ModelDiscoveryServiceTests
```

Expected: FAIL with missing `HTTPClient` and `ModelDiscoveryService`.

- [ ] **Step 3: Add model discovery DTO**

Append to `Sources/WorkerManagerCore/Domain.swift`:

```swift
public struct ProviderModelListResponse: Decodable, Sendable {
    public struct ProviderModel: Decodable, Sendable {
        public let id: String
    }

    public let data: [ProviderModel]
}
```

- [ ] **Step 4: Create HTTP client abstraction**

Create `Sources/WorkerManagerCore/HTTPClient.swift`:

```swift
import Foundation

public protocol HTTPClient: AnyObject, Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

extension URLSession: HTTPClient {}
```

- [ ] **Step 5: Create model discovery service**

Create `Sources/WorkerManagerCore/ModelDiscoveryService.swift`:

```swift
import Foundation

public final class ModelDiscoveryService: Sendable {
    private let httpClient: HTTPClient
    private let credentialStore: CredentialStore
    private let decoder = JSONDecoder()

    public init(
        httpClient: HTTPClient = URLSession.shared,
        credentialStore: CredentialStore = KeychainCredentialStore()
    ) {
        self.httpClient = httpClient
        self.credentialStore = credentialStore
    }

    public func discoverModels(for provider: ModelProvider) async throws -> [WorkerModel] {
        guard let apiKey = try await credentialStore.apiKey(for: provider.apiKeyReference) else {
            throw WorkerManagerError.missingAPIKey(provider.apiKeyReference)
        }

        let template = ProviderCatalog.template(for: provider.kind)
            ?? ProviderTemplate(kind: provider.kind, name: provider.name, defaultBaseURL: provider.baseURL)
        let url = provider.baseURL.appendingPathComponent(template.modelsPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await httpClient.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            throw WorkerManagerError.invalidResponse("Model discovery returned HTTP \(response.statusCode)")
        }

        let decoded = try decoder.decode(ProviderModelListResponse.self, from: data)
        return decoded.data.map { item in
            WorkerModel(
                providerID: provider.id,
                name: item.id,
                displayName: item.id,
                supportsStreaming: true,
                supportsToolUse: false,
                isCustom: false
            )
        }
    }
}
```

- [ ] **Step 6: Run tests**

Run:

```bash
swift test --filter ModelDiscoveryServiceTests
```

Expected: PASS.

- [ ] **Step 7: Commit**

Run:

```bash
git add Sources/WorkerManagerCore Tests/WorkerManagerCoreTests/ModelDiscoveryServiceTests.swift
git commit -m "feat: discover provider models"
```

Expected: commit succeeds.

---

### Task 5: Add Worker Execution Service

**Files:**
- Modify: `Sources/WorkerManagerCore/Domain.swift`
- Create: `Sources/WorkerManagerCore/WorkerExecutionService.swift`
- Create: `Tests/WorkerManagerCoreTests/WorkerExecutionServiceTests.swift`

- [ ] **Step 1: Write failing worker execution test**

Create `Tests/WorkerManagerCoreTests/WorkerExecutionServiceTests.swift`:

```swift
import XCTest
@testable import WorkerManagerCore

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

        XCTAssertTrue(result.patchText.contains("+print(\\\"new\\\")"))
        XCTAssertEqual(result.modelName, "deepseek-v4-pro")
        XCTAssertEqual(http.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test")
    }
}

private final class MockExecutionHTTPClient: HTTPClient {
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
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter WorkerExecutionServiceTests
```

Expected: FAIL with missing worker execution types.

- [ ] **Step 3: Add execution domain types**

Append to `Sources/WorkerManagerCore/Domain.swift`:

```swift
public struct WorkerTask: Codable, Equatable, Sendable {
    public let modelName: String
    public let instruction: String
    public let workspacePath: String

    public init(modelName: String, instruction: String, workspacePath: String) {
        self.modelName = modelName
        self.instruction = instruction
        self.workspacePath = workspacePath
    }
}

public struct WorkerExecutionResult: Codable, Equatable, Sendable {
    public let modelName: String
    public let patchText: String
    public let rawResponse: String

    public init(modelName: String, patchText: String, rawResponse: String) {
        self.modelName = modelName
        self.patchText = patchText
        self.rawResponse = rawResponse
    }
}
```

- [ ] **Step 4: Create execution service**

Create `Sources/WorkerManagerCore/WorkerExecutionService.swift`:

```swift
import Foundation

public final class WorkerExecutionService: Sendable {
    private struct ChatRequest: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }

        let model: String
        let messages: [Message]
        let temperature: Double
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String
            }

            let message: Message
        }

        let choices: [Choice]
    }

    private let httpClient: HTTPClient
    private let credentialStore: CredentialStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        httpClient: HTTPClient = URLSession.shared,
        credentialStore: CredentialStore = KeychainCredentialStore()
    ) {
        self.httpClient = httpClient
        self.credentialStore = credentialStore
    }

    public func run(
        task: WorkerTask,
        provider: ModelProvider,
        model: WorkerModel
    ) async throws -> WorkerExecutionResult {
        guard let apiKey = try await credentialStore.apiKey(for: provider.apiKeyReference) else {
            throw WorkerManagerError.missingAPIKey(provider.apiKeyReference)
        }

        let prompt = """
        You are an implementation worker. Produce a unified diff only.

        Workspace:
        \(task.workspacePath)

        Task:
        \(task.instruction)
        """

        let template = ProviderCatalog.template(for: provider.kind)
            ?? ProviderTemplate(kind: provider.kind, name: provider.name, defaultBaseURL: provider.baseURL)
        let url = provider.baseURL.appendingPathComponent(template.chatCompletionsPath.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        let body = ChatRequest(
            model: model.name,
            messages: [
                .init(role: "system", content: "Return only a unified diff. Do not explain."),
                .init(role: "user", content: prompt)
            ],
            temperature: 0.2
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await httpClient.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            throw WorkerManagerError.invalidResponse("Worker execution returned HTTP \(response.statusCode)")
        }

        let decoded = try decoder.decode(ChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw WorkerManagerError.invalidResponse("Worker response had no message content")
        }

        return WorkerExecutionResult(
            modelName: model.name,
            patchText: extractDiff(from: content),
            rawResponse: content
        )
    }

    private func extractDiff(from content: String) -> String {
        let fence = "```"
        guard content.contains(fence) else {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var lines = content.components(separatedBy: .newlines)
        if lines.first?.hasPrefix("```") == true {
            lines.removeFirst()
        }
        if lines.last?.hasPrefix("```") == true {
            lines.removeLast()
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

- [ ] **Step 5: Run tests**

Run:

```bash
swift test --filter WorkerExecutionServiceTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/WorkerManagerCore/WorkerExecutionService.swift Sources/WorkerManagerCore/Domain.swift Tests/WorkerManagerCoreTests/WorkerExecutionServiceTests.swift
git commit -m "feat: execute delegated worker tasks"
```

Expected: commit succeeds.

---

### Task 6: Build CLI Bridge for Codex

**Files:**
- Modify: `Sources/WorkerManagerCLI/main.swift`
- Create: `Tests/WorkerManagerCLITests/WorkerManagerCLITests.swift`
- Modify: `README.md`

- [ ] **Step 1: Write CLI smoke tests**

Create `Tests/WorkerManagerCLITests/WorkerManagerCLITests.swift`:

```swift
import XCTest

final class WorkerManagerCLITests: XCTestCase {
    func testArgumentParserRecognizesListModels() throws {
        let command = CLICommand.parse(["list-models"])

        XCTAssertEqual(command, .listModels)
    }

    func testArgumentParserRecognizesRun() throws {
        let command = CLICommand.parse([
            "run",
            "--model", "deepseek-v4-pro",
            "--task-file", "/tmp/task.md",
            "--workspace", "/tmp/workspace"
        ])

        XCTAssertEqual(
            command,
            .run(model: "deepseek-v4-pro", taskFile: "/tmp/task.md", workspace: "/tmp/workspace")
        )
    }
}
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
swift test --filter WorkerManagerCLITests
```

Expected: FAIL because `CLICommand` is not visible to tests.

- [ ] **Step 3: Move CLI parsing into core**

Create `Sources/WorkerManagerCore/CLICommand.swift`:

```swift
import Foundation

public enum CLICommand: Equatable, Sendable {
    case listModels
    case run(model: String, taskFile: String, workspace: String)
    case help

    public static func parse(_ arguments: [String]) -> CLICommand {
        guard let first = arguments.first else {
            return .help
        }

        switch first {
        case "list-models":
            return .listModels
        case "run":
            guard
                let model = value(after: "--model", in: arguments),
                let taskFile = value(after: "--task-file", in: arguments),
                let workspace = value(after: "--workspace", in: arguments)
            else {
                return .help
            }
            return .run(model: model, taskFile: taskFile, workspace: workspace)
        default:
            return .help
        }
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag) else {
            return nil
        }
        let valueIndex = arguments.index(after: index)
        guard valueIndex < arguments.endIndex else {
            return nil
        }
        return arguments[valueIndex]
    }
}
```

- [ ] **Step 4: Implement CLI main**

Replace `Sources/WorkerManagerCLI/main.swift` with:

```swift
import Foundation
import WorkerManagerCore

@main
struct WorkerManagerCLI {
    static func main() async {
        let command = CLICommand.parse(Array(CommandLine.arguments.dropFirst()))
        let store = ProviderStore()

        do {
            switch command {
            case .listModels:
                let config = try await store.load()
                for model in config.models.sorted(by: { $0.name < $1.name }) {
                    print("\(model.name)\t\(model.displayName)")
                }
            case .run(let modelName, let taskFile, let workspace):
                let config = try await store.load()
                guard let model = config.models.first(where: { $0.name == modelName }) else {
                    throw WorkerManagerError.modelNotFound(modelName)
                }
                guard let provider = config.providers.first(where: { $0.id == model.providerID }) else {
                    throw WorkerManagerError.providerNotFound(model.providerID)
                }

                let instruction = try String(contentsOfFile: taskFile, encoding: .utf8)
                let service = WorkerExecutionService()
                let result = try await service.run(
                    task: WorkerTask(modelName: modelName, instruction: instruction, workspacePath: workspace),
                    provider: provider,
                    model: model
                )
                print(result.patchText)
            case .help:
                print(Self.helpText)
            }
        } catch {
            fputs("worker-manager-cli error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static let helpText = """
    Usage:
      worker-manager-cli list-models
      worker-manager-cli run --model <name> --task-file <path> --workspace <path>
    """
}
```

- [ ] **Step 5: Update README with Codex usage**

Append to `README.md`:

```markdown
## Codex Delegation Flow

1. GPT/Codex writes a task file:

```bash
cat > /tmp/worker-task.md
```

2. Codex asks the configured worker model to produce a diff:

```bash
swift run worker-manager-cli run \
  --model deepseek-v4-pro \
  --task-file /tmp/worker-task.md \
  --workspace /path/to/target/project
```

3. GPT reviews the returned diff.
4. GPT applies only approved edits to files.
```

- [ ] **Step 6: Run tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 7: Commit**

Run:

```bash
git add Sources/WorkerManagerCore/CLICommand.swift Sources/WorkerManagerCLI/main.swift Tests/WorkerManagerCLITests README.md
git commit -m "feat: expose codex worker delegation cli"
```

Expected: commit succeeds.

---

### Task 7: Build SwiftUI Provider and Model Management UI

**Files:**
- Create: `Sources/WorkerManagerApp/AppViewModel.swift`
- Create: `Sources/WorkerManagerApp/ContentView.swift`
- Modify: `Sources/WorkerManagerApp/WorkerManagerApp.swift`

- [ ] **Step 1: Create app view model**

Create `Sources/WorkerManagerApp/AppViewModel.swift`:

```swift
import Foundation
import Observation
import WorkerManagerCore

@MainActor
@Observable
final class AppViewModel {
    var providers: [ModelProvider] = []
    var models: [WorkerModel] = []
    var selectedProviderID: UUID?
    var statusMessage: String = ""
    var newProviderName: String = "DeepSeek"
    var newProviderKind: ProviderKind = .deepSeek
    var newProviderBaseURL: String = "https://api.deepseek.com"
    var newProviderAPIKey: String = ""
    var customModelName: String = "deepseek-v4-pro"
    var customModelDisplayName: String = "DeepSeek V4 Pro"

    private let store: ProviderStore
    private let credentialStore: CredentialStore
    private let discoveryService: ModelDiscoveryService

    init(
        store: ProviderStore = ProviderStore(),
        credentialStore: CredentialStore = KeychainCredentialStore()
    ) {
        self.store = store
        self.credentialStore = credentialStore
        self.discoveryService = ModelDiscoveryService(credentialStore: credentialStore)
    }

    func load() async {
        do {
            let configuration = try await store.load()
            providers = configuration.providers
            models = configuration.models
            selectedProviderID = providers.first?.id
            statusMessage = "Loaded \(providers.count) providers and \(models.count) models."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func addProvider() async {
        guard let baseURL = URL(string: newProviderBaseURL), !newProviderAPIKey.isEmpty else {
            statusMessage = "Enter a valid base URL and API key."
            return
        }

        let reference = "provider.\(newProviderName.lowercased().replacingOccurrences(of: " ", with: "-"))"
        let provider = ModelProvider(
            name: newProviderName,
            kind: newProviderKind,
            baseURL: baseURL,
            apiKeyReference: reference
        )

        do {
            try await credentialStore.saveAPIKey(newProviderAPIKey, for: reference)
            providers.append(provider)
            selectedProviderID = provider.id
            try await save()
            statusMessage = "Added provider \(provider.name)."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func fetchModelsForSelectedProvider() async {
        guard let provider = selectedProvider else {
            statusMessage = "Select a provider first."
            return
        }

        do {
            let discovered = try await discoveryService.discoverModels(for: provider)
            models.removeAll { $0.providerID == provider.id && !$0.isCustom }
            models.append(contentsOf: discovered)
            try await save()
            statusMessage = "Fetched \(discovered.count) models from \(provider.name)."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func addCustomModel() async {
        guard let provider = selectedProvider, !customModelName.isEmpty else {
            statusMessage = "Select a provider and enter a model name."
            return
        }

        models.append(
            WorkerModel(
                providerID: provider.id,
                name: customModelName,
                displayName: customModelDisplayName.isEmpty ? customModelName : customModelDisplayName,
                isCustom: true
            )
        )

        do {
            try await save()
            statusMessage = "Added custom model \(customModelName)."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    var selectedProvider: ModelProvider? {
        providers.first { $0.id == selectedProviderID }
    }

    var visibleModels: [WorkerModel] {
        guard let selectedProviderID else {
            return []
        }
        return models.filter { $0.providerID == selectedProviderID }.sorted { $0.name < $1.name }
    }

    private func save() async throws {
        try await store.save(WorkerManagerConfiguration(providers: providers, models: models))
    }
}
```

- [ ] **Step 2: Create content view**

Create `Sources/WorkerManagerApp/ContentView.swift`:

```swift
import SwiftUI
import WorkerManagerCore

struct ContentView: View {
    @State private var viewModel = AppViewModel()

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedProviderID) {
                ForEach(viewModel.providers) { provider in
                    Text(provider.name)
                        .tag(provider.id)
                }
            }
            .navigationTitle("Providers")
            .safeAreaInset(edge: .bottom) {
                providerForm
                    .padding()
            }
        } detail: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(viewModel.selectedProvider?.name ?? "No Provider Selected")
                        .font(.title2)
                    Spacer()
                    Button("Fetch Models") {
                        Task { await viewModel.fetchModelsForSelectedProvider() }
                    }
                    .disabled(viewModel.selectedProvider == nil)
                }

                Table(viewModel.visibleModels) {
                    TableColumn("Model") { model in
                        Text(model.name)
                    }
                    TableColumn("Display Name") { model in
                        Text(model.displayName)
                    }
                    TableColumn("Source") { model in
                        Text(model.isCustom ? "Custom" : "Provider")
                    }
                }

                customModelForm

                Text(viewModel.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .frame(minWidth: 960, minHeight: 640)
        .task {
            await viewModel.load()
        }
    }

    private var providerForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Provider name", text: $viewModel.newProviderName)
            Picker("Kind", selection: $viewModel.newProviderKind) {
                ForEach(ProviderKind.allCases, id: \.self) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            TextField("Base URL", text: $viewModel.newProviderBaseURL)
            SecureField("API key", text: $viewModel.newProviderAPIKey)
            Button("Add Provider") {
                Task { await viewModel.addProvider() }
            }
        }
    }

    private var customModelForm: some View {
        HStack {
            TextField("Custom model name", text: $viewModel.customModelName)
            TextField("Display name", text: $viewModel.customModelDisplayName)
            Button("Add Model") {
                Task { await viewModel.addCustomModel() }
            }
            .disabled(viewModel.selectedProvider == nil)
        }
    }
}
```

- [ ] **Step 3: Wire content view into app**

Replace `Sources/WorkerManagerApp/WorkerManagerApp.swift` with:

```swift
import SwiftUI

@main
struct WorkerManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Step 4: Build app**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 5: Launch app manually**

Run:

```bash
swift run WorkerManagerApp
```

Expected: macOS window opens with provider list, provider form, model table, and custom model form.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/WorkerManagerApp
git commit -m "feat: add macos provider management ui"
```

Expected: commit succeeds.

---

### Task 8: Add Delegation Preview in App

**Files:**
- Modify: `Sources/WorkerManagerApp/AppViewModel.swift`
- Modify: `Sources/WorkerManagerApp/ContentView.swift`

- [ ] **Step 1: Extend view model for preview**

Append these properties and method inside `AppViewModel`:

```swift
var delegationInstruction: String = "Implement the requested feature and return a unified diff."
var selectedModelName: String?
var generatedPatchPreview: String = ""

func runDelegationPreview() async {
    guard
        let selectedModelName,
        let model = models.first(where: { $0.name == selectedModelName }),
        let provider = providers.first(where: { $0.id == model.providerID })
    else {
        statusMessage = "Select a model before running a preview."
        return
    }

    do {
        let service = WorkerExecutionService()
        let result = try await service.run(
            task: WorkerTask(
                modelName: model.name,
                instruction: delegationInstruction,
                workspacePath: FileManager.default.currentDirectoryPath
            ),
            provider: provider,
            model: model
        )
        generatedPatchPreview = result.patchText
        statusMessage = "Preview generated by \(model.name)."
    } catch {
        statusMessage = error.localizedDescription
    }
}
```

- [ ] **Step 2: Set selected model when adding model**

In `addCustomModel()`, replace the direct `models.append(...)` block with:

```swift
let model = WorkerModel(
    providerID: provider.id,
    name: customModelName,
    displayName: customModelDisplayName.isEmpty ? customModelName : customModelDisplayName,
    isCustom: true
)
models.append(model)
selectedModelName = model.name
```

- [ ] **Step 3: Add preview UI**

In `ContentView`, insert this view below `customModelForm`:

```swift
Divider()

VStack(alignment: .leading, spacing: 8) {
    HStack {
        Picker("Worker Model", selection: $viewModel.selectedModelName) {
            Text("Select").tag(Optional<String>.none)
            ForEach(viewModel.models.sorted { $0.name < $1.name }) { model in
                Text(model.name).tag(Optional(model.name))
            }
        }
        Button("Run Preview") {
            Task { await viewModel.runDelegationPreview() }
        }
        .disabled(viewModel.selectedModelName == nil)
    }

    TextEditor(text: $viewModel.delegationInstruction)
        .font(.body)
        .frame(minHeight: 90)

    TextEditor(text: $viewModel.generatedPatchPreview)
        .font(.system(.body, design: .monospaced))
        .frame(minHeight: 160)
}
```

- [ ] **Step 4: Build app**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

Run:

```bash
git add Sources/WorkerManagerApp
git commit -m "feat: preview delegated worker output"
```

Expected: commit succeeds.

---

### Task 9: Final Verification and Developer Documentation

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update README with full workflow**

Replace `README.md` with:

```markdown
# Worker Manager

Worker Manager is a macOS app and CLI bridge for configuring model providers and worker models. Codex can use the CLI bridge to delegate implementation tasks to configured models while GPT keeps planning, review, and final file-write decisions.

## Build and Test

```bash
swift build
swift test
```

## Run the App

```bash
swift run WorkerManagerApp
```

## Configure DeepSeek

1. Open the app.
2. Add provider:
   - Provider name: `DeepSeek`
   - Kind: `deepSeek`
   - Base URL: `https://api.deepseek.com`
   - API key: your DeepSeek API key
3. Click `Fetch Models`.
4. Add custom model:
   - Model name: `deepseek-v4-pro`
   - Display name: `DeepSeek V4 Pro`

## Codex Delegation Flow

GPT remains responsible for planning, code review, and final write decisions. Worker Manager only supplies the configured execution model.

```bash
cat > /tmp/worker-task.md <<'TASK'
Implement the requested feature and return a unified diff only.
TASK

swift run worker-manager-cli run \
  --model deepseek-v4-pro \
  --task-file /tmp/worker-task.md \
  --workspace /path/to/target/project
```

Codex should review the returned diff before applying it.

## Config Location

Provider and model metadata is stored at:

```text
~/.worker-manager/config.json
```

API keys are stored in macOS Keychain under service:

```text
com.worker-manager.credentials
```
```

- [ ] **Step 2: Run full test suite**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 3: Build both executables**

Run:

```bash
swift build
```

Expected: PASS.

- [ ] **Step 4: Verify CLI help**

Run:

```bash
swift run worker-manager-cli
```

Expected output includes:

```text
Usage:
  worker-manager-cli list-models
  worker-manager-cli run --model <name> --task-file <path> --workspace <path>
```

- [ ] **Step 5: Commit**

Run:

```bash
git add README.md
git commit -m "docs: document worker manager workflow"
```

Expected: commit succeeds.

---

## Self-Review

**Spec coverage:** The plan covers configuring model providers, securely storing provider API keys, fetching supported models, adding custom models like `deepseek-v4-pro`, exposing a macOS UI, and providing a CLI bridge that Codex can call when GPT wants to delegate implementation work. The final file-writing authority remains with GPT/Codex review, matching the requested “GPT 思考方案 -> worker 生成代码 -> GPT 审核 -> 写入文件” flow.

**Placeholder scan:** No task uses unresolved placeholders, “similar to,” or unspecified “add appropriate handling” language. Every code-producing step includes concrete code.

**Type consistency:** `ModelProvider`, `WorkerModel`, `WorkerManagerConfiguration`, `CredentialStore`, `HTTPClient`, `ModelDiscoveryService`, `WorkerExecutionService`, `WorkerTask`, `WorkerExecutionResult`, and `CLICommand` are introduced before use or in the same task that first requires them.

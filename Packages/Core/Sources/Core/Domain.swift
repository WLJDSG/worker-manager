import Foundation

public enum ProviderKind: String, Codable, CaseIterable, Hashable, Sendable {
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

public struct ProviderModelListResponse: Decodable, Sendable {
    public struct ProviderModel: Decodable, Sendable {
        public let id: String
    }

    public let data: [ProviderModel]
}

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

public struct ProviderConnectionTestResult: Codable, Equatable, Sendable {
    public let providerName: String
    public let discoveredModelCount: Int
    public let message: String

    public init(providerName: String, discoveredModelCount: Int, message: String) {
        self.providerName = providerName
        self.discoveredModelCount = discoveredModelCount
        self.message = message
    }
}

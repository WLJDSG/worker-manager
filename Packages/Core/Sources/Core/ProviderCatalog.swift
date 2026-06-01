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

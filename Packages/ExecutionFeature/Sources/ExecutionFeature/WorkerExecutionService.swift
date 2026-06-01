import Foundation
import Core

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

    public init(
        httpClient: HTTPClient = URLSessionHTTPClient(),
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
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await httpClient.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            throw WorkerManagerError.invalidResponse("Worker execution returned HTTP \(response.statusCode)")
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
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
import Foundation

public final class ProviderConnectionTestService: Sendable {
    private let httpClient: HTTPClient
    private let credentialStore: CredentialStore

    public init(
        httpClient: HTTPClient = URLSessionHTTPClient(),
        credentialStore: CredentialStore = KeychainCredentialStore()
    ) {
        self.httpClient = httpClient
        self.credentialStore = credentialStore
    }

    public func testConnection(for provider: ModelProvider) async throws -> ProviderConnectionTestResult {
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
            throw WorkerManagerError.invalidResponse("Provider test returned HTTP \(response.statusCode)")
        }

        let decoded = try JSONDecoder().decode(ProviderModelListResponse.self, from: data)
        return ProviderConnectionTestResult(
            providerName: provider.name,
            discoveredModelCount: decoded.data.count,
            message: "Connected to \(provider.name). Found \(decoded.data.count) models."
        )
    }
}

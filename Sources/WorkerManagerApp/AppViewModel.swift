import Foundation
import WorkerManagerCore

@MainActor
final class AppViewModel: ObservableObject {
    @Published var providers: [ModelProvider] = []
    @Published var models: [WorkerModel] = []
    @Published var selectedProviderID: UUID?
    @Published var statusMessage: String = ""
    @Published var newProviderName: String = "DeepSeek"
    @Published var newProviderKind: ProviderKind = .deepSeek
    @Published var newProviderBaseURL: String = "https://api.deepseek.com"
    @Published var newProviderAPIKey: String = ""
    @Published var customModelName: String = "deepseek-v4-pro"
    @Published var customModelDisplayName: String = "DeepSeek V4 Pro"
    @Published var delegationInstruction: String = "Implement the requested feature and return a unified diff."
    @Published var selectedModelName: String?
    @Published var generatedPatchPreview: String = ""

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
            selectedModelName = models.first?.name
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
            newProviderAPIKey = ""
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
            selectedModelName = discovered.first?.name ?? selectedModelName
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

        let model = WorkerModel(
            providerID: provider.id,
            name: customModelName,
            displayName: customModelDisplayName.isEmpty ? customModelName : customModelDisplayName,
            isCustom: true
        )
        models.append(model)
        selectedModelName = model.name

        do {
            try await save()
            statusMessage = "Added custom model \(customModelName)."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

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

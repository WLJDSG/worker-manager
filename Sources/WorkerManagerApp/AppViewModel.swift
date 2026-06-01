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
    @Published var providerTestMessage: String = ""
    @Published var isTestingProvider: Bool = false

    private let store: ProviderStore
    private let credentialStore: CredentialStore
    private let discoveryService: ModelDiscoveryService
    private let connectionTestService: ProviderConnectionTestService

    init(
        store: ProviderStore = ProviderStore(),
        credentialStore: CredentialStore = KeychainCredentialStore()
    ) {
        self.store = store
        self.credentialStore = credentialStore
        self.discoveryService = ModelDiscoveryService(credentialStore: credentialStore)
        self.connectionTestService = ProviderConnectionTestService(credentialStore: credentialStore)
    }

    func load() async {
        do {
            let configuration = try await store.load()
            providers = configuration.providers
            models = configuration.models
            selectedProviderID = providers.first?.id
            selectedModelName = models.first?.name
            statusMessage = "已加载 \(providers.count) 个厂商、\(models.count) 个模型。"
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func addProvider() async {
        guard let baseURL = URL(string: newProviderBaseURL), !newProviderAPIKey.isEmpty else {
            statusMessage = "请输入有效的 Base URL 和 API Key。"
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
            statusMessage = "已添加厂商：\(provider.name)。"
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func fetchModelsForSelectedProvider() async {
        guard let provider = selectedProvider else {
            statusMessage = "请先选择一个厂商。"
            return
        }

        do {
            let discovered = try await discoveryService.discoverModels(for: provider)
            models.removeAll { $0.providerID == provider.id && !$0.isCustom }
            models.append(contentsOf: discovered)
            selectedModelName = discovered.first?.name ?? selectedModelName
            try await save()
            statusMessage = "已从 \(provider.name) 获取 \(discovered.count) 个模型。"
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func testSelectedProvider() async {
        guard let provider = selectedProvider else {
            statusMessage = "请先选择一个厂商。"
            return
        }

        isTestingProvider = true
        providerTestMessage = "正在测试 \(provider.name)..."
        defer { isTestingProvider = false }

        do {
            let result = try await connectionTestService.testConnection(for: provider)
            providerTestMessage = "连接成功，发现 \(result.discoveredModelCount) 个模型。"
            statusMessage = "\(result.providerName) 配置可用。"
        } catch {
            providerTestMessage = "连接失败：\(error.localizedDescription)"
            statusMessage = providerTestMessage
        }
    }

    func addCustomModel() async {
        guard let provider = selectedProvider, !customModelName.isEmpty else {
            statusMessage = "请选择厂商并输入模型名称。"
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
            statusMessage = "已添加自定义模型：\(customModelName)。"
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
            statusMessage = "已由 \(model.name) 生成预览。"
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

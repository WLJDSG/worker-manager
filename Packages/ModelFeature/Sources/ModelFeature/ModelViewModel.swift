import Foundation
import Combine
import Core

@MainActor
public class ModelViewModel: ObservableObject {
    @Published public var customModelName: String = "deepseek-v4-pro"
    @Published public var customModelDisplayName: String = "DeepSeek V4 Pro"
    @Published public var isFetchingModels: Bool = false

    private let appState: AppState
    private let credentialStore: CredentialStore
    private let discoveryService: ModelDiscoveryService

    public init(
        appState: AppState,
        credentialStore: CredentialStore = KeychainCredentialStore()
    ) {
        self.appState = appState
        self.credentialStore = credentialStore
        self.discoveryService = ModelDiscoveryService(credentialStore: credentialStore)
    }

    public func fetchModelsForSelectedProvider() async {
        guard let provider = appState.selectedProvider else {
            appState.setStatus("请先选择一个厂商。", kind: .failure)
            return
        }

        isFetchingModels = true
        defer { isFetchingModels = false }

        do {
            let discovered = try await discoveryService.discoverModels(for: provider)
            appState.models.removeAll { $0.providerID == provider.id && !$0.isCustom }
            appState.models.append(contentsOf: discovered)
            appState.selectedModelName = discovered.first?.name ?? appState.selectedModelName
            try await appState.save()
            appState.setStatus("已从 \(provider.name) 获取 \(discovered.count) 个模型。", kind: .success)
        } catch {
            appState.setStatus(error.localizedDescription, kind: .failure)
        }
    }

    public func addCustomModel() async {
        guard let provider = appState.selectedProvider, !customModelName.isEmpty else {
            appState.setStatus("请选择厂商并输入模型名称。", kind: .failure)
            return
        }

        let model = WorkerModel(
            providerID: provider.id,
            name: customModelName,
            displayName: customModelDisplayName.isEmpty ? customModelName : customModelDisplayName,
            isCustom: true
        )
        appState.models.append(model)
        appState.selectedModelName = model.name

        do {
            try await appState.save()
            appState.setStatus("已添加自定义模型：\(customModelName)。", kind: .success)
        } catch {
            appState.setStatus(error.localizedDescription, kind: .failure)
        }
    }

    public func deleteModel(_ model: WorkerModel) async {
        appState.models.removeAll { $0.id == model.id }
        if appState.selectedModelName == model.name {
            appState.selectedModelName = appState.models.first { $0.providerID == model.providerID }?.name
        }

        do {
            try await appState.save()
            appState.setStatus("已删除模型：\(model.name)。", kind: .success)
        } catch {
            appState.setStatus(error.localizedDescription, kind: .failure)
        }
    }
}
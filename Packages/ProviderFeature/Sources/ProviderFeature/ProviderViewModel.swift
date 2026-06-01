import Foundation
import Combine
import Core

@MainActor
public class ProviderViewModel: ObservableObject {
    @Published public var newProviderName: String = "DeepSeek"
    @Published public var newProviderKind: ProviderKind = .deepSeek
    @Published public var newProviderBaseURL: String = "https://api.deepseek.com"
    @Published public var newProviderAPIKey: String = ""
    @Published public var editProviderName: String = ""
    @Published public var editProviderKind: ProviderKind = .deepSeek
    @Published public var editProviderBaseURL: String = ""
    @Published public var editProviderAPIKey: String = ""
    @Published public var providerTestMessage: String = ""
    @Published public var isTestingProvider: Bool = false

    private let appState: AppState
    private let credentialStore: CredentialStore
    private let connectionTestService: ProviderConnectionTestService

    public init(
        appState: AppState,
        credentialStore: CredentialStore = KeychainCredentialStore()
    ) {
        self.appState = appState
        self.credentialStore = credentialStore
        self.connectionTestService = ProviderConnectionTestService(credentialStore: credentialStore)
    }

    public func addProvider() async {
        let name = newProviderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            appState.setStatus("请输入厂商名称。", kind: .failure)
            return
        }
        guard let baseURL = validatedURL(from: newProviderBaseURL) else {
            appState.setStatus("请输入有效的 Base URL。", kind: .failure)
            return
        }
        guard !newProviderAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            appState.setStatus("请输入 API Key。", kind: .failure)
            return
        }

        let reference = "provider.\(name.lowercased().replacingOccurrences(of: " ", with: "-"))"
        let provider = ModelProvider(
            name: name,
            kind: newProviderKind,
            baseURL: baseURL,
            apiKeyReference: reference
        )

        do {
            try await credentialStore.saveAPIKey(newProviderAPIKey, for: reference)
            appState.providers.append(provider)
            appState.selectedProviderID = provider.id
            newProviderAPIKey = ""
            syncEditFieldsWithSelection()
            try await appState.save()
            appState.setStatus("已添加厂商：\(provider.name)。", kind: .success)
        } catch {
            appState.setStatus(error.localizedDescription, kind: .failure)
        }
    }

    public func testSelectedProvider() async {
        guard let provider = appState.selectedProvider else {
            appState.setStatus("请先选择一个厂商。", kind: .failure)
            return
        }

        isTestingProvider = true
        providerTestMessage = "正在测试 \(provider.name)..."
        defer { isTestingProvider = false }

        do {
            let result = try await connectionTestService.testConnection(for: provider)
            providerTestMessage = "连接成功，发现 \(result.discoveredModelCount) 个模型。"
            appState.setStatus("\(result.providerName) 配置可用。", kind: .success)
        } catch {
            providerTestMessage = "连接失败：\(error.localizedDescription)"
            appState.setStatus(providerTestMessage, kind: .failure)
        }
    }

    public func saveSelectedProviderEdits() async {
        guard let provider = appState.selectedProvider,
              let index = appState.providers.firstIndex(where: { $0.id == provider.id }) else {
            appState.setStatus("请先选择一个厂商。", kind: .failure)
            return
        }

        let name = editProviderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            appState.setStatus("请输入厂商名称。", kind: .failure)
            return
        }
        guard let baseURL = validatedURL(from: editProviderBaseURL) else {
            appState.setStatus("请输入有效的 Base URL。", kind: .failure)
            return
        }

        do {
            let replacementKey = editProviderAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !replacementKey.isEmpty {
                try await credentialStore.saveAPIKey(replacementKey, for: provider.apiKeyReference)
            }

            appState.providers[index] = ModelProvider(
                id: provider.id,
                name: name,
                kind: editProviderKind,
                baseURL: baseURL,
                apiKeyReference: provider.apiKeyReference,
                isEnabled: provider.isEnabled
            )
            editProviderAPIKey = ""
            try await appState.save()
            appState.setStatus("已保存厂商：\(name)。", kind: .success)
        } catch {
            appState.setStatus(error.localizedDescription, kind: .failure)
        }
    }

    public func deleteSelectedProvider() async {
        guard let provider = appState.selectedProvider else {
            appState.setStatus("请先选择一个厂商。", kind: .failure)
            return
        }

        appState.providers.removeAll { $0.id == provider.id }
        appState.models.removeAll { $0.providerID == provider.id }
        appState.selectedProviderID = appState.providers.first?.id
        appState.selectedModelName = appState.selectedProviderID.flatMap { providerID in
            appState.models.first { $0.providerID == providerID }?.name
        }
        syncEditFieldsWithSelection()

        do {
            try await appState.save()
            appState.setStatus("已删除厂商：\(provider.name)。", kind: .success)
        } catch {
            appState.setStatus(error.localizedDescription, kind: .failure)
        }
    }

    public func syncEditFieldsWithSelection() {
        guard let selectedProvider = appState.selectedProvider else {
            editProviderName = ""
            editProviderKind = .deepSeek
            editProviderBaseURL = ""
            editProviderAPIKey = ""
            return
        }

        editProviderName = selectedProvider.name
        editProviderKind = selectedProvider.kind
        editProviderBaseURL = selectedProvider.baseURL.absoluteString
        editProviderAPIKey = ""
    }

    private func validatedURL(from value: String) -> URL? {
        guard let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }
        return url
    }
}
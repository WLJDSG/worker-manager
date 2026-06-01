import Foundation
import Combine

@MainActor
public class AppState: ObservableObject {
    @Published public var providers: [ModelProvider] = []
    @Published public var models: [WorkerModel] = []
    @Published public var selectedProviderID: UUID?
    @Published public var selectedModelName: String?
    @Published public var statusMessage: String = ""
    @Published public var lastStatusKind: StatusKind = .neutral

    private let store: ProviderStore

    public init(store: ProviderStore = ProviderStore()) {
        self.store = store
    }

    public func load() async {
        do {
            let configuration = try await store.load()
            providers = configuration.providers
            models = configuration.models
            selectedProviderID = providers.first?.id
            selectedModelName = models.first?.name
            setStatus("已加载 \(providers.count) 个厂商、\(models.count) 个模型。", kind: .success)
        } catch {
            setStatus(error.localizedDescription, kind: .failure)
        }
    }

    public func save() async throws {
        try await store.save(WorkerManagerConfiguration(providers: providers, models: models))
    }

    public func setStatus(_ message: String, kind: StatusKind) {
        statusMessage = message
        lastStatusKind = kind
    }

    public var selectedProvider: ModelProvider? {
        providers.first { $0.id == selectedProviderID }
    }

    public var visibleModels: [WorkerModel] {
        guard let selectedProviderID else { return [] }
        return models.filter { $0.providerID == selectedProviderID }.sorted { $0.name < $1.name }
    }
}
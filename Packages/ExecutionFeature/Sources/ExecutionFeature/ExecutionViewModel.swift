import Foundation
import Combine
import Core

@MainActor
public class ExecutionViewModel: ObservableObject {
    @Published public var delegationInstruction: String = "Implement the requested feature and return a unified diff."
    @Published public var generatedPatchPreview: String = ""

    private let appState: AppState
    private let credentialStore: CredentialStore

    public init(
        appState: AppState,
        credentialStore: CredentialStore = KeychainCredentialStore()
    ) {
        self.appState = appState
        self.credentialStore = credentialStore
    }

    public func runDelegationPreview() async {
        guard
            let selectedModelName = appState.selectedModelName,
            let model = appState.models.first(where: { $0.name == selectedModelName }),
            let provider = appState.providers.first(where: { $0.id == model.providerID })
        else {
            appState.setStatus("运行预览前请选择模型。", kind: .failure)
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
            appState.setStatus("已由 \(model.name) 生成预览。", kind: .success)
        } catch {
            appState.setStatus(error.localizedDescription, kind: .failure)
        }
    }

    public func clearGeneratedPreview() {
        generatedPatchPreview = ""
        appState.setStatus("已清空预览。", kind: .neutral)
    }
}
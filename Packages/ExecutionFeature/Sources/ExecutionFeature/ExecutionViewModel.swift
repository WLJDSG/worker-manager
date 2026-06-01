import Foundation
import Combine
import Core

@MainActor
public class ExecutionViewModel: ObservableObject {
    @Published public var delegationInstruction: String = "Implement the requested feature and return a unified diff."
    @Published public var generatedPatchPreview: String = ""
    @Published public var chatDraft: String = ""
    @Published public var chatMessages: [ChatMessage] = []
    @Published public var isSendingChatMessage: Bool = false

    private let appState: AppState
    private let credentialStore: CredentialStore
    private let chatService: ChatTestingService

    public init(
        appState: AppState,
        credentialStore: CredentialStore = KeychainCredentialStore(),
        chatService: ChatTestingService? = nil
    ) {
        self.appState = appState
        self.credentialStore = credentialStore
        self.chatService = chatService ?? WorkerExecutionService(credentialStore: credentialStore)
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

    public func sendChatMessage() async {
        guard
            let selectedModelName = appState.selectedModelName,
            let model = appState.models.first(where: { $0.name == selectedModelName }),
            let provider = appState.providers.first(where: { $0.id == model.providerID })
        else {
            appState.setStatus("发送前请选择模型。", kind: .failure)
            return
        }

        let prompt = chatDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            appState.setStatus("请输入要发送的消息。", kind: .failure)
            return
        }

        let userMessage = ChatMessage(role: .user, content: prompt)
        chatMessages.append(userMessage)
        chatDraft = ""
        isSendingChatMessage = true
        defer { isSendingChatMessage = false }

        do {
            let response = try await chatService.sendChat(
                messages: chatMessages,
                provider: provider,
                model: model
            )
            chatMessages.append(ChatMessage(role: .assistant, content: response))
            appState.setStatus("模型已回复。", kind: .success)
        } catch {
            appState.setStatus("对话测试失败：\(error.localizedDescription)", kind: .failure)
        }
    }

    public func clearConversation() {
        chatDraft = ""
        chatMessages = []
        appState.setStatus("已清空会话。", kind: .neutral)
    }
}

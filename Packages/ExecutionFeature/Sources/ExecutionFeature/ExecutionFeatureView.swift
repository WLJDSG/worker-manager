import SwiftUI
import Core
import SharedUI

public struct ExecutionFeatureView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var executionVM: ExecutionViewModel

    public init(appState: AppState, executionVM: ExecutionViewModel) {
        self.appState = appState
        self.executionVM = executionVM
    }

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Picker("测试模型", selection: $appState.selectedModelName) {
                        Text("请选择模型").tag(Optional<String>.none)
                        ForEach(appState.models.sorted { $0.name < $1.name }) { model in
                            Text(model.name).tag(Optional(model.name))
                        }
                    }

                    Spacer()

                    Button {
                        executionVM.clearConversation()
                    } label: {
                        Label("清空会话", systemImage: "trash")
                    }
                    .disabled(executionVM.chatMessages.isEmpty && executionVM.chatDraft.isEmpty)
                }

                if executionVM.chatMessages.isEmpty {
                    EmptyStateView(
                        systemImage: "bubble.left.and.bubble.right",
                        title: "还没有对话",
                        message: "选择模型后输入一条消息，测试模型是否能正常回复。"
                    )
                    .frame(minHeight: 280)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 10) {
                                ForEach(executionVM.chatMessages) { message in
                                    ChatMessageBubble(message: message)
                                        .id(message.id)
                                }

                                if executionVM.isSendingChatMessage {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .controlSize(.small)
                                        Text("模型回复中...")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            .padding(12)
                        }
                        .frame(minHeight: 280)
                        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                        .onChange(of: executionVM.chatMessages.count) { _ in
                            if let last = executionVM.chatMessages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                HStack(alignment: .bottom, spacing: 10) {
                    TextField("输入测试消息...", text: $executionVM.chatDraft, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .disabled(executionVM.isSendingChatMessage)
                        .onSubmit {
                            Task { await executionVM.sendChatMessage() }
                        }

                    Button {
                        Task { await executionVM.sendChatMessage() }
                    } label: {
                        Label(executionVM.isSendingChatMessage ? "发送中..." : "发送", systemImage: "paperplane.fill")
                    }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(appState.selectedModelName == nil || executionVM.chatDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || executionVM.isSendingChatMessage)
                }
            }
        } label: {
            Label("对话测试", systemImage: "bubble.left.and.bubble.right")
        }
    }
}

private struct ChatMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 80)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.role == .user ? "你" : "模型")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(message.content)
                    .textSelection(.enabled)
            }
            .padding(10)
            .background(message.role == .user ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            if message.role == .assistant {
                Spacer(minLength: 80)
            }
        }
    }
}

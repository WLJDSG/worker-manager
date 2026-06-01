import SwiftUI
import Core
import SharedUI

public struct ProviderFeatureView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var providerVM: ProviderViewModel
    @State private var isConfirmingProviderDeletion = false

    public init(appState: AppState, providerVM: ProviderViewModel) {
        self.appState = appState
        self.providerVM = providerVM
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 20) {
            GroupBox {
                if appState.providers.isEmpty {
                    EmptyStateView(
                        systemImage: "server.rack",
                        title: "还没有厂商",
                        message: "添加一个厂商后，就可以测试连接并获取模型列表。"
                    )
                    .frame(minWidth: 280, minHeight: 260)
                } else {
                    List(selection: $appState.selectedProviderID) {
                        ForEach(appState.providers) { provider in
                            providerRow(provider)
                                .tag(provider.id)
                        }
                    }
                    .listStyle(.sidebar)
                    .frame(minWidth: 280)
                }
            } label: {
                Label("已配置厂商", systemImage: "list.bullet.rectangle")
            }

            VStack(alignment: .leading, spacing: 16) {
                selectedProviderSummary
                providerForm
                StatusFooterView(
                    iconName: statusIcon,
                    color: statusColor,
                    message: appState.statusMessage.isEmpty ? "就绪" : appState.statusMessage
                )
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .confirmationDialog("删除当前厂商？", isPresented: $isConfirmingProviderDeletion) {
            Button("删除厂商", role: .destructive) {
                Task { await providerVM.deleteSelectedProvider() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除厂商会同时移除它下面的模型配置。")
        }
    }

    private func providerRow(_ provider: ModelProvider) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(provider.name)
                .font(.headline)
                .lineLimit(1)
            Text(provider.baseURL.absoluteString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
    }

    private var selectedProviderSummary: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Text(appState.selectedProvider?.name ?? "未选择厂商")
                    .font(.title2)
                    .fontWeight(.semibold)

                if let provider = appState.selectedProvider {
                    Text("编辑当前厂商信息。替换 Key 留空时会继续使用现有 Key。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 10) {
                        GridRow {
                            Text("厂商名称")
                            TextField("厂商名称", text: $providerVM.editProviderName)
                        }
                        GridRow {
                            Text("厂商类型")
                            Picker("", selection: $providerVM.editProviderKind) {
                                ForEach(ProviderKind.allCases, id: \.self) { kind in
                                    Text(kind.rawValue).tag(kind)
                                }
                            }
                            .labelsHidden()
                        }
                        GridRow {
                            Text("Base URL")
                            TextField("https://api.example.com", text: $providerVM.editProviderBaseURL)
                        }
                        GridRow {
                            Text("替换 Key")
                            SecureField("留空则保留当前 Key", text: $providerVM.editProviderAPIKey)
                        }
                        GridRow {
                            Text("Key 引用")
                            Text(provider.apiKeyReference)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            Task { await providerVM.saveSelectedProviderEdits() }
                        } label: {
                            Label("保存修改", systemImage: "checkmark")
                        }
                        .keyboardShortcut("s", modifiers: [.command])

                        Button {
                            Task { await providerVM.testSelectedProvider() }
                        } label: {
                            Label(providerVM.isTestingProvider ? "测试中..." : "测试连接", systemImage: "checkmark.seal")
                        }
                        .disabled(providerVM.isTestingProvider)

                        Button(role: .destructive) {
                            isConfirmingProviderDeletion = true
                        } label: {
                            Label("删除厂商", systemImage: "trash")
                        }

                        Spacer()
                    }

                    Text(providerVM.providerTestMessage.isEmpty ? "连接测试会调用厂商模型列表接口，验证 Base URL、API Key 和接口路径。" : providerVM.providerTestMessage)
                        .font(.footnote)
                        .foregroundStyle(providerVM.providerTestMessage.hasPrefix("连接失败") ? .red : .secondary)
                } else {
                    Text("从左侧选择一个厂商，或在下方添加新的厂商配置。")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("厂商详情", systemImage: "info.circle")
        }
    }

    private var providerForm: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("填写新厂商的连接信息，添加后会自动选中它。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 10) {
                    GridRow {
                        Text("厂商名称")
                        TextField("例如 DeepSeek", text: $providerVM.newProviderName)
                    }
                    GridRow {
                        Text("厂商类型")
                        Picker("", selection: $providerVM.newProviderKind) {
                            ForEach(ProviderKind.allCases, id: \.self) { kind in
                                Text(kind.rawValue).tag(kind)
                            }
                        }
                        .labelsHidden()
                    }
                    GridRow {
                        Text("Base URL")
                        TextField("https://api.deepseek.com", text: $providerVM.newProviderBaseURL)
                    }
                    GridRow {
                        Text("API Key")
                        SecureField("输入厂商 API Key", text: $providerVM.newProviderAPIKey)
                    }
                    GridRow {
                        Color.clear.frame(width: 1, height: 1)
                        Button {
                            Task { await providerVM.addProvider() }
                        } label: {
                            Label("添加厂商", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        } label: {
            Label("新增厂商", systemImage: "plus.circle")
        }
    }

    private var statusIcon: String {
        switch appState.lastStatusKind {
        case .neutral: return "circle"
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch appState.lastStatusKind {
        case .neutral: return .secondary
        case .success: return .green
        case .failure: return .red
        }
    }
}

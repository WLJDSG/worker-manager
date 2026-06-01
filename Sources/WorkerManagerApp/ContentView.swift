import SwiftUI
import WorkerManagerCore

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        TabView {
            providerTab
                .tabItem {
                    Label("厂商", systemImage: "server.rack")
                }

            modelTab
                .tabItem {
                    Label("模型", systemImage: "cpu")
                }
        }
        .padding(20)
        .frame(minWidth: 980, minHeight: 680)
        .task {
            await viewModel.load()
        }
    }

    private var providerTab: some View {
        HStack(alignment: .top, spacing: 20) {
            GroupBox {
                List(selection: $viewModel.selectedProviderID) {
                    ForEach(viewModel.providers) { provider in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(provider.name)
                                .font(.headline)
                            Text(provider.baseURL.absoluteString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 4)
                        .tag(provider.id)
                    }
                }
                .frame(minWidth: 260)
            } label: {
                Label("已配置厂商", systemImage: "list.bullet.rectangle")
            }

            VStack(alignment: .leading, spacing: 16) {
                selectedProviderSummary
                providerForm
                providerTestPanel
                statusFooter
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var modelTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Picker("当前厂商", selection: $viewModel.selectedProviderID) {
                    Text("请选择厂商").tag(Optional<UUID>.none)
                    ForEach(viewModel.providers) { provider in
                        Text(provider.name).tag(Optional(provider.id))
                    }
                }
                .frame(width: 280)

                Button {
                    Task { await viewModel.fetchModelsForSelectedProvider() }
                } label: {
                    Label("获取模型", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(viewModel.selectedProvider == nil)

                Spacer()
            }

            GroupBox {
                Table(viewModel.visibleModels) {
                    TableColumn("模型名称") { model in
                        Text(model.name)
                    }
                    TableColumn("显示名称") { model in
                        Text(model.displayName)
                    }
                    TableColumn("来源") { model in
                        Text(model.isCustom ? "自定义" : "厂商")
                    }
                }
                .frame(minHeight: 230)
            } label: {
                Label("模型列表", systemImage: "square.stack.3d.up")
            }

            customModelForm
            delegationPreview
            statusFooter
        }
    }

    private var selectedProviderSummary: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.selectedProvider?.name ?? "未选择厂商")
                    .font(.title2)
                    .fontWeight(.semibold)

                if let provider = viewModel.selectedProvider {
                    LabeledContent("类型", value: provider.kind.rawValue)
                    LabeledContent("Base URL", value: provider.baseURL.absoluteString)
                    LabeledContent("Key 引用", value: provider.apiKeyReference)
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
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    Text("厂商名称")
                    TextField("例如 DeepSeek", text: $viewModel.newProviderName)
                }
                GridRow {
                    Text("厂商类型")
                    Picker("", selection: $viewModel.newProviderKind) {
                        ForEach(ProviderKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    .labelsHidden()
                }
                GridRow {
                    Text("Base URL")
                    TextField("https://api.deepseek.com", text: $viewModel.newProviderBaseURL)
                }
                GridRow {
                    Text("API Key")
                    SecureField("输入厂商 API Key", text: $viewModel.newProviderAPIKey)
                }
                GridRow {
                    Color.clear.frame(width: 1, height: 1)
                    Button {
                        Task { await viewModel.addProvider() }
                    } label: {
                        Label("添加厂商", systemImage: "plus")
                    }
                }
            }
        } label: {
            Label("新增厂商", systemImage: "plus.circle")
        }
    }

    private var providerTestPanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Button {
                        Task { await viewModel.testSelectedProvider() }
                    } label: {
                        Label(viewModel.isTestingProvider ? "测试中..." : "测试厂商配置", systemImage: "checkmark.seal")
                    }
                    .disabled(viewModel.selectedProvider == nil || viewModel.isTestingProvider)

                    Spacer()
                }

                Text(viewModel.providerTestMessage.isEmpty ? "测试会调用厂商模型列表接口，用来验证 Base URL、API Key 和接口路径是否可用。" : viewModel.providerTestMessage)
                    .font(.footnote)
                    .foregroundStyle(viewModel.providerTestMessage.hasPrefix("连接失败") ? .red : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label("连接测试", systemImage: "network")
        }
    }

    private var customModelForm: some View {
        GroupBox {
            HStack(spacing: 10) {
                TextField("自定义模型名称", text: $viewModel.customModelName)
                TextField("显示名称", text: $viewModel.customModelDisplayName)
                Button {
                    Task { await viewModel.addCustomModel() }
                } label: {
                    Label("添加模型", systemImage: "plus")
                }
                .disabled(viewModel.selectedProvider == nil)
            }
        } label: {
            Label("自定义模型", systemImage: "square.and.pencil")
        }
    }

    private var delegationPreview: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Picker("Worker 模型", selection: $viewModel.selectedModelName) {
                        Text("请选择模型").tag(Optional<String>.none)
                        ForEach(viewModel.models.sorted { $0.name < $1.name }) { model in
                            Text(model.name).tag(Optional(model.name))
                        }
                    }
                    Button {
                        Task { await viewModel.runDelegationPreview() }
                    } label: {
                        Label("运行预览", systemImage: "play")
                    }
                    .disabled(viewModel.selectedModelName == nil)
                }

                TextEditor(text: $viewModel.delegationInstruction)
                    .font(.body)
                    .frame(minHeight: 90)

                TextEditor(text: $viewModel.generatedPatchPreview)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 150)
            }
        } label: {
            Label("委托预览", systemImage: "terminal")
        }
    }

    private var statusFooter: some View {
        Text(viewModel.statusMessage.isEmpty ? "就绪" : viewModel.statusMessage)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

import SwiftUI
import Core
import SharedUI

public struct ModelFeatureView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var modelVM: ModelViewModel
    @State private var isConfirmingModelDeletion = false
    @State private var modelPendingDeletion: WorkerModel?

    public init(appState: AppState, modelVM: ModelViewModel) {
        self.appState = appState
        self.modelVM = modelVM
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Picker("当前厂商", selection: $appState.selectedProviderID) {
                    Text("请选择厂商").tag(Optional<UUID>.none)
                    ForEach(appState.providers) { provider in
                        Text(provider.name).tag(Optional(provider.id))
                    }
                }
                .frame(width: 280)

                Button {
                    Task { await modelVM.fetchModelsForSelectedProvider() }
                } label: {
                    Label(modelVM.isFetchingModels ? "获取中..." : "获取模型", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(appState.selectedProvider == nil || modelVM.isFetchingModels)

                Spacer()
            }

            GroupBox {
                if appState.visibleModels.isEmpty {
                    EmptyStateView(
                        systemImage: "cpu",
                        title: appState.selectedProvider == nil ? "请选择厂商" : "还没有模型",
                        message: appState.selectedProvider == nil ? "先选择一个厂商，再获取或添加模型。" : "可以从厂商获取模型，也可以添加自定义模型。"
                    )
                    .frame(minHeight: 230)
                } else {
                    Table(appState.visibleModels) {
                        TableColumn("模型名称") { model in
                            Text(model.name)
                        }
                        TableColumn("显示名称") { model in
                            Text(model.displayName)
                        }
                        TableColumn("来源") { model in
                            Text(model.isCustom ? "自定义" : "厂商")
                        }
                        TableColumn("") { model in
                            Button(role: .destructive) {
                                modelPendingDeletion = model
                                isConfirmingModelDeletion = true
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .help("删除模型")
                        }
                        .width(44)
                    }
                    .frame(minHeight: 230)
                }
            } label: {
                Label("模型列表", systemImage: "square.stack.3d.up")
            }

            customModelForm
        }
        .confirmationDialog("删除模型？", isPresented: $isConfirmingModelDeletion) {
            Button("删除模型", role: .destructive) {
                if let model = modelPendingDeletion {
                    Task { await modelVM.deleteModel(model) }
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将删除 \(modelPendingDeletion?.name ?? "当前模型")。")
        }
    }

    private var customModelForm: some View {
        GroupBox {
            HStack(spacing: 10) {
                TextField("自定义模型名称", text: $modelVM.customModelName)
                TextField("显示名称", text: $modelVM.customModelDisplayName)
                Button {
                    Task { await modelVM.addCustomModel() }
                } label: {
                    Label("添加模型", systemImage: "plus")
                }
                .disabled(appState.selectedProvider == nil)
            }
        } label: {
            Label("自定义模型", systemImage: "square.and.pencil")
        }
    }
}
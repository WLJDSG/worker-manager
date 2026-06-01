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
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Picker("Worker 模型", selection: $appState.selectedModelName) {
                        Text("请选择模型").tag(Optional<String>.none)
                        ForEach(appState.models.sorted { $0.name < $1.name }) { model in
                            Text(model.name).tag(Optional(model.name))
                        }
                    }
                    Button {
                        Task { await executionVM.runDelegationPreview() }
                    } label: {
                        Label("运行预览", systemImage: "play")
                    }
                    .disabled(appState.selectedModelName == nil)

                    Button {
                        executionVM.clearGeneratedPreview()
                    } label: {
                        Label("清空预览", systemImage: "xmark.circle")
                    }
                    .disabled(executionVM.generatedPatchPreview.isEmpty)
                }

                TextEditor(text: $executionVM.delegationInstruction)
                    .font(.body)
                    .frame(minHeight: 90)

                if executionVM.generatedPatchPreview.isEmpty {
                    EmptyStateView(
                        systemImage: "doc.text.magnifyingglass",
                        title: "还没有预览结果",
                        message: "选择模型后运行预览，生成的 diff 会显示在这里。"
                    )
                    .frame(minHeight: 150)
                } else {
                    TextEditor(text: $executionVM.generatedPatchPreview)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 150)
                }
            }
        } label: {
            Label("委托预览", systemImage: "terminal")
        }
    }
}
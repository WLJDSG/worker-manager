import SwiftUI
import Core
import ProviderFeature
import ModelFeature
import ExecutionFeature
import SharedUI

struct ContentView: View {
    @StateObject private var appState: AppState
    @StateObject private var providerVM: ProviderViewModel
    @StateObject private var modelVM: ModelViewModel
    @StateObject private var executionVM: ExecutionViewModel

    init() {
        let store = ProviderStore()
        let credentials: CredentialStore = KeychainCredentialStore()
        let state = AppState(store: store)
        _appState = StateObject(wrappedValue: state)
        _providerVM = StateObject(wrappedValue: ProviderViewModel(appState: state, credentialStore: credentials))
        _modelVM = StateObject(wrappedValue: ModelViewModel(appState: state, credentialStore: credentials))
        _executionVM = StateObject(wrappedValue: ExecutionViewModel(appState: state, credentialStore: credentials))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            TabView {
                ProviderFeatureView(appState: appState, providerVM: providerVM)
                    .tabItem {
                        Label("厂商", systemImage: "server.rack")
                    }

                VStack(alignment: .leading, spacing: 16) {
                    ModelFeatureView(appState: appState, modelVM: modelVM)
                    ExecutionFeatureView(appState: appState, executionVM: executionVM)
                    StatusFooterView(
                        iconName: statusIcon,
                        color: statusColor,
                        message: appState.statusMessage.isEmpty ? "就绪" : appState.statusMessage
                    )
                }
                .tabItem {
                    Label("模型", systemImage: "cpu")
                }
            }
        }
        .padding(24)
        .frame(minWidth: 1_040, minHeight: 720)
        .task {
            await appState.load()
            providerVM.syncEditFieldsWithSelection()
        }
        .onChange(of: appState.selectedProviderID) { _ in
            providerVM.syncEditFieldsWithSelection()
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Worker Manager")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text("管理模型厂商、模型列表和 worker 预览配置。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Label("\(appState.providers.count) 个厂商 · \(appState.models.count) 个模型", systemImage: "rectangle.stack")
                .font(.callout)
                .foregroundStyle(.secondary)
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
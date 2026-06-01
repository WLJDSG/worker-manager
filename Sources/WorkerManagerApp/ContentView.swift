import SwiftUI
import WorkerManagerCore

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedProviderID) {
                ForEach(viewModel.providers) { provider in
                    Text(provider.name)
                        .tag(provider.id)
                }
            }
            .navigationTitle("Providers")
            .safeAreaInset(edge: .bottom) {
                providerForm
                    .padding()
            }
        } detail: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(viewModel.selectedProvider?.name ?? "No Provider Selected")
                        .font(.title2)
                    Spacer()
                    Button("Fetch Models") {
                        Task { await viewModel.fetchModelsForSelectedProvider() }
                    }
                    .disabled(viewModel.selectedProvider == nil)
                }

                Table(viewModel.visibleModels) {
                    TableColumn("Model") { model in
                        Text(model.name)
                    }
                    TableColumn("Display Name") { model in
                        Text(model.displayName)
                    }
                    TableColumn("Source") { model in
                        Text(model.isCustom ? "Custom" : "Provider")
                    }
                }

                customModelForm

                Divider()

                delegationPreview

                Text(viewModel.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .frame(minWidth: 960, minHeight: 640)
        .task {
            await viewModel.load()
        }
    }

    private var providerForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Provider name", text: $viewModel.newProviderName)
            Picker("Kind", selection: $viewModel.newProviderKind) {
                ForEach(ProviderKind.allCases, id: \.self) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            TextField("Base URL", text: $viewModel.newProviderBaseURL)
            SecureField("API key", text: $viewModel.newProviderAPIKey)
            Button("Add Provider") {
                Task { await viewModel.addProvider() }
            }
        }
    }

    private var customModelForm: some View {
        HStack {
            TextField("Custom model name", text: $viewModel.customModelName)
            TextField("Display name", text: $viewModel.customModelDisplayName)
            Button("Add Model") {
                Task { await viewModel.addCustomModel() }
            }
            .disabled(viewModel.selectedProvider == nil)
        }
    }

    private var delegationPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Worker Model", selection: $viewModel.selectedModelName) {
                    Text("Select").tag(Optional<String>.none)
                    ForEach(viewModel.models.sorted { $0.name < $1.name }) { model in
                        Text(model.name).tag(Optional(model.name))
                    }
                }
                Button("Run Preview") {
                    Task { await viewModel.runDelegationPreview() }
                }
                .disabled(viewModel.selectedModelName == nil)
            }

            TextEditor(text: $viewModel.delegationInstruction)
                .font(.body)
                .frame(minHeight: 90)

            TextEditor(text: $viewModel.generatedPatchPreview)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 160)
        }
    }
}

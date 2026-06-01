import XCTest
@testable import ExecutionFeature
@testable import Core

@MainActor
final class ExecutionViewModelTests: XCTestCase {
    func testClearPreviewOnlyClearsGeneratedPatchPreview() {
        let state = AppState(store: ProviderStore(configURL: temporaryConfigURL()))
        let viewModel = ExecutionViewModel(appState: state, credentialStore: MemoryCredentialStore())
        viewModel.delegationInstruction = "Keep this instruction"
        viewModel.generatedPatchPreview = "diff --git a/file b/file"

        viewModel.clearGeneratedPreview()

        XCTAssertEqual(viewModel.delegationInstruction, "Keep this instruction")
        XCTAssertEqual(viewModel.generatedPatchPreview, "")
    }

    private func temporaryConfigURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("config.json")
    }
}
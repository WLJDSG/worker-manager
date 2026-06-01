import Foundation
import Core
import ExecutionFeature

@main
struct WorkerManagerCLI {
    static func main() async {
        let command = CLICommand.parse(Array(CommandLine.arguments.dropFirst()))
        let store = ProviderStore()

        do {
            switch command {
            case .listModels:
                let config = try await store.load()
                for model in config.models.sorted(by: { $0.name < $1.name }) {
                    print("\(model.name)\t\(model.displayName)")
                }
            case .run(let modelName, let taskFile, let workspace):
                let config = try await store.load()
                guard let model = config.models.first(where: { $0.name == modelName }) else {
                    throw WorkerManagerError.modelNotFound(modelName)
                }
                guard let provider = config.providers.first(where: { $0.id == model.providerID }) else {
                    throw WorkerManagerError.providerNotFound(model.providerID)
                }

                let instruction = try String(contentsOfFile: taskFile, encoding: .utf8)
                let service = WorkerExecutionService()
                let result = try await service.run(
                    task: WorkerTask(modelName: modelName, instruction: instruction, workspacePath: workspace),
                    provider: provider,
                    model: model
                )
                print(result.patchText)
            case .help:
                print(Self.helpText)
            }
        } catch {
            fputs("worker-manager-cli error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static let helpText = """
    Usage:
      worker-manager-cli list-models
      worker-manager-cli run --model <name> --task-file <path> --workspace <path>
    """
}
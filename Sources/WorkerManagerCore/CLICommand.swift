import Foundation

public enum CLICommand: Equatable, Sendable {
    case listModels
    case run(model: String, taskFile: String, workspace: String)
    case help

    public static func parse(_ arguments: [String]) -> CLICommand {
        guard let first = arguments.first else {
            return .help
        }

        switch first {
        case "list-models":
            return .listModels
        case "run":
            guard
                let model = value(after: "--model", in: arguments),
                let taskFile = value(after: "--task-file", in: arguments),
                let workspace = value(after: "--workspace", in: arguments)
            else {
                return .help
            }
            return .run(model: model, taskFile: taskFile, workspace: workspace)
        default:
            return .help
        }
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag) else {
            return nil
        }
        let valueIndex = arguments.index(after: index)
        guard valueIndex < arguments.endIndex else {
            return nil
        }
        return arguments[valueIndex]
    }
}

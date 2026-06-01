import XCTest
@testable import Core
@testable import ExecutionFeature

final class WorkerManagerCLITests: XCTestCase {
    func testArgumentParserRecognizesListModels() throws {
        let command = CLICommand.parse(["list-models"])

        XCTAssertEqual(command, .listModels)
    }

    func testArgumentParserRecognizesRun() throws {
        let command = CLICommand.parse([
            "run",
            "--model", "deepseek-v4-pro",
            "--task-file", "/tmp/task.md",
            "--workspace", "/tmp/workspace"
        ])

        XCTAssertEqual(
            command,
            .run(model: "deepseek-v4-pro", taskFile: "/tmp/task.md", workspace: "/tmp/workspace")
        )
    }
}
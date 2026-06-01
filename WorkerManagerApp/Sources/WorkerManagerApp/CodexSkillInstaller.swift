import Foundation

enum CodexSkillInstaller {
    private static let skillName = "worker-manager"

    static func installBundledSkillIfNeeded(
        bundle: Bundle = .module,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        guard let sourceURL = bundle.url(
            forResource: "SKILL",
            withExtension: "md",
            subdirectory: "Resources/CodexSkills/\(skillName)"
        ) else {
            return
        }

        let destinationDirectory = homeDirectory
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("skills", isDirectory: true)
            .appendingPathComponent(skillName, isDirectory: true)
        let destinationURL = destinationDirectory.appendingPathComponent("SKILL.md")

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                return
            }

            let sourceData = try Data(contentsOf: sourceURL)
            try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
            try sourceData.write(to: destinationURL, options: .atomic)
        } catch {
            NSLog("WorkerManager failed to install bundled Codex skill: \(error.localizedDescription)")
        }
    }
}

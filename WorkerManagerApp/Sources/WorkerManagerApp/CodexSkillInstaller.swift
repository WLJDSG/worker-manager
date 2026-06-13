import Foundation

enum CodexSkillInstaller {
    private static let skillName = "worker-manager"
    private static let skillSubdirectory = "CodexSkills/\(skillName)"

    static func installBundledSkillIfNeeded(
        bundle: Bundle = .module,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        guard let sourceURL = findBundledSkill() else {
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

    private static func findBundledSkill() -> URL? {
        // When packaged as a .app, the SKILL.md sits under Contents/Resources/CodexSkills/
        if let url = Bundle.main.url(
            forResource: "SKILL",
            withExtension: "md",
            subdirectory: skillSubdirectory
        ) {
            return url
        }

        // Bundled in SPM resource bundle for development builds
        if let url = Bundle.module.url(
            forResource: "SKILL",
            withExtension: "md",
            subdirectory: "Resources/\(skillSubdirectory)"
        ) {
            return url
        }

        return nil
    }
}

import SwiftUI

@main
struct WorkerManagerApp: App {
    init() {
        CodexSkillInstaller.installBundledSkillIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

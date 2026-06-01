import Foundation

public actor ProviderStore {
    private let configURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(configURL: URL = ProviderStore.defaultConfigURL()) {
        self.configURL = configURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func load() async throws -> WorkerManagerConfiguration {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return WorkerManagerConfiguration()
        }

        let data = try Data(contentsOf: configURL)
        return try decoder.decode(WorkerManagerConfiguration.self, from: data)
    }

    public func save(_ configuration: WorkerManagerConfiguration) async throws {
        let directory = configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(configuration)
        try data.write(to: configURL, options: .atomic)
    }

    public static func defaultConfigURL() -> URL {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".worker-manager", isDirectory: true)
        return base.appendingPathComponent("config.json")
    }
}

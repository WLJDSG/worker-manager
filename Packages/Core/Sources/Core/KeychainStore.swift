import Foundation
import Security

public protocol CredentialStore: Sendable {
    func saveAPIKey(_ apiKey: String, for reference: String) async throws
    func apiKey(for reference: String) async throws -> String?
    func deleteAPIKey(for reference: String) async throws
}

public actor MemoryCredentialStore: CredentialStore {
    private var values: [String: String] = [:]

    public init() {}

    public func saveAPIKey(_ apiKey: String, for reference: String) async throws {
        values[reference] = apiKey
    }

    public func apiKey(for reference: String) async throws -> String? {
        values[reference]
    }

    public func deleteAPIKey(for reference: String) async throws {
        values.removeValue(forKey: reference)
    }
}

public struct KeychainCredentialStore: CredentialStore {
    private let service: String

    public init(service: String = "com.worker-manager.credentials") {
        self.service = service
    }

    public func saveAPIKey(_ apiKey: String, for reference: String) async throws {
        let data = Data(apiKey.utf8)
        let query = baseQuery(reference: reference)
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw WorkerManagerError.invalidResponse("Keychain save failed with status \(status)")
        }
    }

    public func apiKey(for reference: String) async throws -> String? {
        var query = baseQuery(reference: reference)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw WorkerManagerError.invalidResponse("Keychain read failed with status \(status)")
        }
        return String(data: data, encoding: .utf8)
    }

    public func deleteAPIKey(for reference: String) async throws {
        let status = SecItemDelete(baseQuery(reference: reference) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw WorkerManagerError.invalidResponse("Keychain delete failed with status \(status)")
        }
    }

    private func baseQuery(reference: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: reference
        ]
    }
}

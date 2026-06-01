import Foundation
import Core

public struct ChatMessage: Identifiable, Equatable, Sendable {
    public enum Role: String, Equatable, Sendable {
        case user
        case assistant
    }

    public let id: UUID
    public let role: Role
    public let content: String

    public init(id: UUID = UUID(), role: Role, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }
}

public protocol ChatTestingService: Sendable {
    func sendChat(
        messages: [ChatMessage],
        provider: ModelProvider,
        model: WorkerModel
    ) async throws -> String
}

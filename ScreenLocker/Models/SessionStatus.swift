import Foundation

enum SessionStatus: String, Codable, CaseIterable {
    case active
    case completed
    case broken
}

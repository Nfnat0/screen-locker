import Foundation

enum UnlockReason: String, Codable, CaseIterable, Identifiable {
    case urgentReply
    case specificApp
    case changedMind
    case lockTooLong
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .urgentReply:
            "I need to reply urgently"
        case .specificApp:
            "I need a specific app"
        case .changedMind:
            "I changed my mind"
        case .lockTooLong:
            "The lock was too long"
        case .other:
            "Other"
        }
    }
}

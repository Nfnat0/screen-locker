import Foundation

enum BlockingAuthorizationState: String {
    case notDetermined
    case approved
    case denied
    case unavailable

    var title: String {
        switch self {
        case .notDetermined:
            "Not Requested"
        case .approved:
            "Allowed"
        case .denied:
            "Denied"
        case .unavailable:
            "Unavailable"
        }
    }

    var userMessage: String {
        switch self {
        case .notDetermined:
            "Screen Time access has not been requested yet."
        case .approved:
            "Screen Time access is allowed."
        case .denied:
            "Screen Time access is denied. The timer can still run without app shielding."
        case .unavailable:
            "Screen Time APIs are unavailable in this build or configuration."
        }
    }
}

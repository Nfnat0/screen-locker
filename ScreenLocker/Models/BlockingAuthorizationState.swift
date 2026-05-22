import Foundation

enum BlockingAuthorizationState: String {
    case notDetermined
    case approved
    case denied
    case restricted
    case unavailable

    var title: String {
        switch self {
        case .notDetermined:
            "Not Requested"
        case .approved:
            "Allowed"
        case .denied:
            "Denied"
        case .restricted:
            "Restricted"
        case .unavailable:
            "Unavailable"
        }
    }

    var detail: String {
        switch self {
        case .notDetermined:
            "Request Screen Time access to shield selected apps during detox sessions."
        case .approved:
            "Screen Time access is available for selected app shields."
        case .denied:
            "Screen Time access was denied. The local timer can still track protected time."
        case .restricted:
            "Screen Time access is restricted on this device or account."
        case .unavailable:
            "Screen Time frameworks or entitlements are not available in this build."
        }
    }
}

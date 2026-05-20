import Foundation

enum ProFeature: String, CaseIterable, Identifiable {
    case unlimitedModes
    case advancedInsights
    case schedules
    case deepLock
    case customThemes
    case widgets
    case liveActivity
    case reflectionLog
    case exportStats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unlimitedModes:
            "Unlimited Modes"
        case .advancedInsights:
            "Advanced Insights"
        case .schedules:
            "Schedules"
        case .deepLock:
            "Deep Lock"
        case .customThemes:
            "Custom Themes"
        case .widgets:
            "Widgets"
        case .liveActivity:
            "Live Activity"
        case .reflectionLog:
            "Reflection Log"
        case .exportStats:
            "Export Stats"
        }
    }

    var subtitle: String {
        switch self {
        case .unlimitedModes:
            "Save multiple detox setups."
        case .advancedInsights:
            "Unlock weekly, monthly, and trend views."
        case .schedules:
            "Plan recurring detox windows."
        case .deepLock:
            "Add an extra layer of protection."
        case .customThemes:
            "Personalize the timer look."
        case .widgets:
            "Track progress from the Home Screen."
        case .liveActivity:
            "Follow a session from the Lock Screen."
        case .reflectionLog:
            "Capture why sessions worked or broke."
        case .exportStats:
            "Export your protected time history."
        }
    }

    var iconName: String {
        switch self {
        case .unlimitedModes:
            "square.grid.2x2.fill"
        case .advancedInsights:
            "chart.xyaxis.line"
        case .schedules:
            "calendar.badge.clock"
        case .deepLock:
            "lock.shield.fill"
        case .customThemes:
            "paintpalette.fill"
        case .widgets:
            "rectangle.grid.1x2.fill"
        case .liveActivity:
            "bolt.badge.clock.fill"
        case .reflectionLog:
            "book.closed.fill"
        case .exportStats:
            "square.and.arrow.up.fill"
        }
    }
}

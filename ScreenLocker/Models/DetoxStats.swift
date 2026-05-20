import Foundation

struct DailyProtectedTime: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let protectedSeconds: TimeInterval

    var protectedMinutes: Int {
        Int(protectedSeconds / 60)
    }
}

struct DetoxStats {
    let protectedTimeToday: TimeInterval
    let protectedTimeAllTime: TimeInterval
    let sessionCountToday: Int
    let averageSessionLength: TimeInterval
    let completionRate: Double
    let currentStreak: Int
    let weeklyProtectedTime: [DailyProtectedTime]
    let extendedTimeTotal: TimeInterval
    let brokenSessionCount: Int

    static let empty = DetoxStats(
        protectedTimeToday: 0,
        protectedTimeAllTime: 0,
        sessionCountToday: 0,
        averageSessionLength: 0,
        completionRate: 0,
        currentStreak: 0,
        weeklyProtectedTime: [],
        extendedTimeTotal: 0,
        brokenSessionCount: 0
    )
}

import Foundation

enum StatsCalculator {
    static func calculate(
        sessions: [DetoxSessionRecord],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> DetoxStats {
        let todayStart = calendar.startOfDay(for: now)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? now
        let completedOrBroken = sessions.filter { $0.status != .active }
        let completedCount = completedOrBroken.filter { $0.status == .completed }.count
        let brokenCount = completedOrBroken.filter { $0.status == .broken }.count

        let protectedToday = sessions.reduce(0) {
            $0 + protectedSeconds(for: $1, from: todayStart, to: tomorrowStart, now: now)
        }

        let protectedAllTime = sessions.reduce(0) {
            $0 + protectedSeconds(for: $1, now: now)
        }

        let todaySessionCount = sessions.filter {
            calendar.isDate($0.startDate, inSameDayAs: now) && $0.status != .active
        }.count

        let averageSession = completedOrBroken.isEmpty ? 0 : completedOrBroken.reduce(0) {
            $0 + protectedSeconds(for: $1, now: now)
        } / Double(completedOrBroken.count)

        let completionRate = completedOrBroken.isEmpty ? 0 : Double(completedCount) / Double(completedOrBroken.count)

        let week = currentWeekDays(containing: now, calendar: calendar)
        let weeklyProtectedTime = week.map { date in
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
            return DailyProtectedTime(
                date: start,
                protectedSeconds: sessions.reduce(0) {
                    $0 + protectedSeconds(for: $1, from: start, to: end, now: now)
                }
            )
        }

        let extendedSeconds = sessions.reduce(0) {
            $0 + TimeInterval($1.extendedMinutes * 60)
        }

        return DetoxStats(
            protectedTimeToday: protectedToday,
            protectedTimeAllTime: protectedAllTime,
            sessionCountToday: todaySessionCount,
            averageSessionLength: averageSession,
            completionRate: completionRate,
            currentStreak: currentStreak(from: sessions, now: now, calendar: calendar),
            weeklyProtectedTime: weeklyProtectedTime,
            extendedTimeTotal: extendedSeconds,
            brokenSessionCount: brokenCount
        )
    }

    private static func protectedSeconds(
        for session: DetoxSessionRecord,
        from intervalStart: Date? = nil,
        to intervalEnd: Date? = nil,
        now: Date
    ) -> TimeInterval {
        let endDate: Date
        switch session.status {
        case .active:
            endDate = min(now, session.plannedEndDate)
        case .completed:
            endDate = session.actualEndDate ?? session.plannedEndDate
        case .broken:
            endDate = session.actualEndDate ?? session.startDate
        }

        var start = session.startDate
        var end = max(start, endDate)

        if let intervalStart {
            start = max(start, intervalStart)
        }

        if let intervalEnd {
            end = min(end, intervalEnd)
        }

        return max(0, end.timeIntervalSince(start))
    }

    private static func currentWeekDays(containing date: Date, calendar: Calendar) -> [Date] {
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfDay) ?? startOfDay

        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: monday)
        }
    }

    private static func currentStreak(
        from sessions: [DetoxSessionRecord],
        now: Date,
        calendar: Calendar
    ) -> Int {
        var streak = 0
        var day = calendar.startOfDay(for: now)

        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let protected = sessions.reduce(0) {
                $0 + protectedSeconds(for: $1, from: day, to: nextDay, now: now)
            }

            guard protected > 0 else { break }
            streak += 1

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else {
                break
            }
            day = previousDay
        }

        return streak
    }
}

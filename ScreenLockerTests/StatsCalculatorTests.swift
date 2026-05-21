import XCTest
@testable import ScreenLocker

final class StatsCalculatorTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testCalculateCountsTodayProtectedTimeFromCompletedAndBrokenSessions() throws {
        let now = try makeDate(year: 2026, month: 5, day: 21, hour: 12, minute: 0)
        let completedStart = try makeDate(year: 2026, month: 5, day: 21, hour: 9, minute: 0)
        let brokenStart = try makeDate(year: 2026, month: 5, day: 21, hour: 11, minute: 0)
        let yesterdayStart = try makeDate(year: 2026, month: 5, day: 20, hour: 9, minute: 0)

        let sessions = [
            makeSession(start: completedStart, plannedMinutes: 60, actualMinutes: 60, status: .completed),
            makeSession(start: brokenStart, plannedMinutes: 60, actualMinutes: 15, status: .broken, reason: .changedMind),
            makeSession(start: yesterdayStart, plannedMinutes: 45, actualMinutes: 45, status: .completed)
        ]

        let stats = StatsCalculator.calculate(sessions: sessions, now: now, calendar: calendar)

        XCTAssertEqual(stats.protectedTimeToday, 75 * 60, accuracy: 0.1)
        XCTAssertEqual(stats.protectedTimeAllTime, 120 * 60, accuracy: 0.1)
        XCTAssertEqual(stats.sessionCountToday, 2)
        XCTAssertEqual(stats.brokenSessionCount, 1)
        XCTAssertEqual(stats.completionRate, 2.0 / 3.0, accuracy: 0.001)
    }

    func testCalculateWeeklyProtectedTimeAggregatesByDay() throws {
        let now = try makeDate(year: 2026, month: 5, day: 21, hour: 12, minute: 0)
        let monday = try makeDate(year: 2026, month: 5, day: 18, hour: 8, minute: 0)
        let thursday = try makeDate(year: 2026, month: 5, day: 21, hour: 8, minute: 0)

        let sessions = [
            makeSession(start: monday, plannedMinutes: 30, actualMinutes: 30, status: .completed),
            makeSession(start: thursday, plannedMinutes: 90, actualMinutes: 90, status: .completed)
        ]

        let stats = StatsCalculator.calculate(sessions: sessions, now: now, calendar: calendar)

        XCTAssertEqual(stats.weeklyProtectedTime.count, 7)
        XCTAssertEqual(stats.weeklyProtectedTime[0].protectedSeconds, 30 * 60, accuracy: 0.1)
        XCTAssertEqual(stats.weeklyProtectedTime[3].protectedSeconds, 90 * 60, accuracy: 0.1)
    }

    func testCalculateCurrentStreakStopsAtMissingDay() throws {
        let now = try makeDate(year: 2026, month: 5, day: 21, hour: 12, minute: 0)
        let today = try makeDate(year: 2026, month: 5, day: 21, hour: 8, minute: 0)
        let yesterday = try makeDate(year: 2026, month: 5, day: 20, hour: 8, minute: 0)
        let threeDaysAgo = try makeDate(year: 2026, month: 5, day: 18, hour: 8, minute: 0)

        let sessions = [
            makeSession(start: today, plannedMinutes: 10, actualMinutes: 10, status: .completed),
            makeSession(start: yesterday, plannedMinutes: 10, actualMinutes: 10, status: .completed),
            makeSession(start: threeDaysAgo, plannedMinutes: 10, actualMinutes: 10, status: .completed)
        ]

        let stats = StatsCalculator.calculate(sessions: sessions, now: now, calendar: calendar)

        XCTAssertEqual(stats.currentStreak, 2)
    }

    func testCalculateTracksExtendedMinutes() throws {
        let now = try makeDate(year: 2026, month: 5, day: 21, hour: 12, minute: 0)
        let start = try makeDate(year: 2026, month: 5, day: 21, hour: 8, minute: 0)

        let session = makeSession(
            start: start,
            plannedMinutes: 60,
            actualMinutes: 75,
            status: .completed,
            extendedMinutes: 15
        )

        let stats = StatsCalculator.calculate(sessions: [session], now: now, calendar: calendar)

        XCTAssertEqual(stats.extendedTimeTotal, 15 * 60, accuracy: 0.1)
        XCTAssertEqual(stats.averageSessionLength, 75 * 60, accuracy: 0.1)
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) throws -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return try XCTUnwrap(components.date)
    }

    private func makeSession(
        start: Date,
        plannedMinutes: Int,
        actualMinutes: Int,
        status: SessionStatus,
        extendedMinutes: Int = 0,
        reason: UnlockReason? = nil
    ) -> DetoxSessionRecord {
        DetoxSessionRecord(
            startDate: start,
            plannedEndDate: start.addingTimeInterval(TimeInterval(plannedMinutes * 60)),
            actualEndDate: start.addingTimeInterval(TimeInterval(actualMinutes * 60)),
            initialDurationMinutes: plannedMinutes - extendedMinutes,
            extendedMinutes: extendedMinutes,
            status: status,
            unlockReason: reason,
            modeId: DetoxMode.defaultModeID,
            modeName: "Default Detox",
            blockedAppCount: 5
        )
    }
}

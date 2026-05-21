import XCTest
@testable import ScreenLocker

final class DetoxSessionRecordTests: XCTestCase {
    func testComputedSessionValuesForActiveSession() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let plannedEnd = start.addingTimeInterval(60 * 60)
        let halfWay = start.addingTimeInterval(30 * 60)
        let session = DetoxSessionRecord(
            startDate: start,
            plannedEndDate: plannedEnd,
            initialDurationMinutes: 60,
            status: .active,
            modeId: DetoxMode.defaultModeID,
            modeName: "Default Detox",
            blockedAppCount: 5
        )

        XCTAssertEqual(session.plannedDuration, 60 * 60, accuracy: 0.1)
        XCTAssertEqual(session.remainingTime(at: halfWay), 30 * 60, accuracy: 0.1)
        XCTAssertEqual(session.progress(at: halfWay), 0.5, accuracy: 0.001)
        XCTAssertFalse(session.wasExtended)
        XCTAssertFalse(session.wasBroken)
    }

    func testComputedSessionValuesForBrokenExtendedSession() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let plannedEnd = start.addingTimeInterval(90 * 60)
        let actualEnd = start.addingTimeInterval(25 * 60)
        let session = DetoxSessionRecord(
            startDate: start,
            plannedEndDate: plannedEnd,
            actualEndDate: actualEnd,
            initialDurationMinutes: 60,
            extendedMinutes: 30,
            status: .broken,
            unlockReason: .lockTooLong,
            modeId: DetoxMode.defaultModeID,
            modeName: "Default Detox",
            blockedAppCount: 5
        )

        XCTAssertEqual(session.totalPlannedMinutes, 90)
        XCTAssertEqual(session.actualDuration(), 25 * 60, accuracy: 0.1)
        XCTAssertTrue(session.wasExtended)
        XCTAssertTrue(session.wasBroken)
        XCTAssertEqual(session.unlockReason, .lockTooLong)
    }
}

import Foundation
import SwiftData

@Model
final class DetoxSessionRecord {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var plannedEndDate: Date
    var actualEndDate: Date?
    var initialDurationMinutes: Int
    var extendedMinutes: Int
    var statusRawValue: String
    var unlockReasonRawValue: String?
    var modeId: UUID?
    var modeName: String
    var blockedAppCount: Int

    init(
        id: UUID = UUID(),
        startDate: Date,
        plannedEndDate: Date,
        actualEndDate: Date? = nil,
        initialDurationMinutes: Int,
        extendedMinutes: Int = 0,
        status: SessionStatus,
        unlockReason: UnlockReason? = nil,
        modeId: UUID?,
        modeName: String,
        blockedAppCount: Int
    ) {
        self.id = id
        self.startDate = startDate
        self.plannedEndDate = plannedEndDate
        self.actualEndDate = actualEndDate
        self.initialDurationMinutes = initialDurationMinutes
        self.extendedMinutes = extendedMinutes
        self.statusRawValue = status.rawValue
        self.unlockReasonRawValue = unlockReason?.rawValue
        self.modeId = modeId
        self.modeName = modeName
        self.blockedAppCount = blockedAppCount
    }

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRawValue) ?? .active }
        set { statusRawValue = newValue.rawValue }
    }

    var unlockReason: UnlockReason? {
        get {
            guard let unlockReasonRawValue else { return nil }
            return UnlockReason(rawValue: unlockReasonRawValue)
        }
        set { unlockReasonRawValue = newValue?.rawValue }
    }

    var plannedDuration: TimeInterval {
        max(0, plannedEndDate.timeIntervalSince(startDate))
    }

    var totalPlannedMinutes: Int {
        initialDurationMinutes + extendedMinutes
    }

    var wasExtended: Bool {
        extendedMinutes > 0
    }

    var wasBroken: Bool {
        status == .broken
    }

    func actualDuration(at date: Date = Date()) -> TimeInterval {
        let endDate = actualEndDate ?? (status == .active ? date : plannedEndDate)
        return max(0, endDate.timeIntervalSince(startDate))
    }

    func remainingTime(at date: Date = Date()) -> TimeInterval {
        max(0, plannedEndDate.timeIntervalSince(date))
    }

    func progress(at date: Date = Date()) -> Double {
        guard plannedDuration > 0 else { return 0 }
        let elapsed = max(0, date.timeIntervalSince(startDate))
        return min(1, elapsed / plannedDuration)
    }
}

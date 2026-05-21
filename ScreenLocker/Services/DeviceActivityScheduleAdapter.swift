import Foundation

#if canImport(DeviceActivity)
import DeviceActivity
#endif

@MainActor
final class DeviceActivityScheduleAdapter {
    enum AdapterResult: Equatable {
        case scheduled
        case cleared
        case unavailable(String)
        case failed(String)
    }

    func apply(_ schedule: DetoxScheduleRecord) -> AdapterResult {
        #if canImport(DeviceActivity)
        guard schedule.isEnabled else {
            return clear(schedule)
        }

        let intervalStart = DateComponents(hour: schedule.startHour, minute: schedule.startMinute)
        let intervalEnd = DateComponents(hour: schedule.endHour, minute: schedule.endMinute)
        let deviceSchedule = DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            repeats: true
        )

        do {
            try DeviceActivityCenter().startMonitoring(
                DeviceActivityName(schedule.id.uuidString),
                during: deviceSchedule
            )
            return .scheduled
        } catch {
            return .failed("DeviceActivity monitoring could not be started.")
        }
        #else
        return .unavailable("DeviceActivity is unavailable in this build.")
        #endif
    }

    func clear(_ schedule: DetoxScheduleRecord) -> AdapterResult {
        #if canImport(DeviceActivity)
        DeviceActivityCenter().stopMonitoring([DeviceActivityName(schedule.id.uuidString)])
        return .cleared
        #else
        return .unavailable("DeviceActivity is unavailable in this build.")
        #endif
    }
}

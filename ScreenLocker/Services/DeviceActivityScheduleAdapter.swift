import Foundation

#if canImport(DeviceActivity)
import DeviceActivity
#endif

struct ScheduleActivationResult: Equatable {
    let isMonitoringActive: Bool
    let message: String
}

final class DeviceActivityScheduleAdapter {
    #if canImport(DeviceActivity)
    private let center = DeviceActivityCenter()
    #endif

    func startMonitoring(schedule: DetoxScheduleRecord) -> ScheduleActivationResult {
        #if canImport(DeviceActivity)
        let activitySchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: schedule.startHour, minute: schedule.startMinute),
            intervalEnd: DateComponents(hour: schedule.endHour, minute: schedule.endMinute),
            repeats: true
        )

        do {
            try center.startMonitoring(DeviceActivityName(schedule.id.uuidString), during: activitySchedule)
            return ScheduleActivationResult(
                isMonitoringActive: true,
                message: "\(schedule.title) monitoring is registered with DeviceActivity."
            )
        } catch {
            return ScheduleActivationResult(
                isMonitoringActive: false,
                message: "DeviceActivity monitoring could not start. Check entitlement setup on a real device."
            )
        }
        #else
        return ScheduleActivationResult(
            isMonitoringActive: false,
            message: "DeviceActivity is unavailable in this build. The schedule is saved locally."
        )
        #endif
    }

    func stopMonitoring(schedule: DetoxScheduleRecord) {
        #if canImport(DeviceActivity)
        center.stopMonitoring([DeviceActivityName(schedule.id.uuidString)])
        #endif
    }
}

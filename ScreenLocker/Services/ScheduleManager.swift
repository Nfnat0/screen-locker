import Foundation
import SwiftData

struct DetoxScheduleDraft {
    var title: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var weekdayRawValues: [Int]
    var isEnabled: Bool
}

@MainActor
final class ScheduleManager: ObservableObject {
    @Published private(set) var schedules: [DetoxScheduleRecord] = []
    @Published var lastMessage: String?

    private var modelContext: ModelContext?
    private let adapter: DeviceActivityScheduleAdapter
    private var isConfigured = false

    init(adapter: DeviceActivityScheduleAdapter = DeviceActivityScheduleAdapter()) {
        self.adapter = adapter
    }

    func configure(modelContext: ModelContext) {
        guard !isConfigured else { return }
        self.modelContext = modelContext
        isConfigured = true
        loadSchedules()
    }

    func loadSchedules() {
        guard let modelContext else { return }

        do {
            let descriptor = FetchDescriptor<DetoxScheduleRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            schedules = try modelContext.fetch(descriptor)
        } catch {
            lastMessage = "Schedules could not be loaded."
        }
    }

    func addSchedule(from draft: DetoxScheduleDraft) {
        guard let modelContext else {
            lastMessage = "Schedule storage is not ready yet."
            return
        }

        let schedule = DetoxScheduleRecord(
            title: draft.title,
            startHour: draft.startHour,
            startMinute: draft.startMinute,
            endHour: draft.endHour,
            endMinute: draft.endMinute,
            weekdayRawValues: draft.weekdayRawValues,
            isEnabled: draft.isEnabled
        )

        modelContext.insert(schedule)
        schedules.insert(schedule, at: 0)
        save()
        applyMonitoringIfNeeded(for: schedule)
    }

    func updateSchedule(_ schedule: DetoxScheduleRecord, with draft: DetoxScheduleDraft) {
        schedule.title = draft.title
        schedule.startHour = draft.startHour
        schedule.startMinute = draft.startMinute
        schedule.endHour = draft.endHour
        schedule.endMinute = draft.endMinute
        schedule.weekdayRawValues = draft.weekdayRawValues.sorted()
        schedule.isEnabled = draft.isEnabled
        schedule.updatedAt = Date()

        save()
        applyMonitoringIfNeeded(for: schedule)
        loadSchedules()
    }

    func setSchedule(_ schedule: DetoxScheduleRecord, isEnabled: Bool) {
        schedule.isEnabled = isEnabled
        schedule.updatedAt = Date()
        save()
        applyMonitoringIfNeeded(for: schedule)
        loadSchedules()
    }

    func deleteSchedule(_ schedule: DetoxScheduleRecord) {
        adapter.stopMonitoring(schedule: schedule)
        modelContext?.delete(schedule)
        schedules.removeAll { $0.id == schedule.id }
        save()
    }

    private func applyMonitoringIfNeeded(for schedule: DetoxScheduleRecord) {
        if schedule.isEnabled {
            let result = adapter.startMonitoring(schedule: schedule)
            lastMessage = result.message
        } else {
            adapter.stopMonitoring(schedule: schedule)
            lastMessage = "\(schedule.title) is saved but disabled."
        }
    }

    private func save() {
        do {
            try modelContext?.save()
        } catch {
            lastMessage = "Your latest schedule change could not be saved."
        }
    }
}

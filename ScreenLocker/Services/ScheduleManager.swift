import Foundation
import SwiftData

@MainActor
final class ScheduleManager: ObservableObject {
    @Published private(set) var schedules: [DetoxScheduleRecord] = []
    @Published var lastErrorMessage: String?

    private var modelContext: ModelContext?
    private let deviceActivityAdapter = DeviceActivityScheduleAdapter()

    func configure(modelContext: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = modelContext
        loadSchedules()
    }

    func loadSchedules() {
        guard let modelContext else { return }

        do {
            let descriptor = FetchDescriptor<DetoxScheduleRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            schedules = try modelContext.fetch(descriptor)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Schedules could not be loaded."
        }
    }

    func addDefaultSchedule() {
        addSchedule(
            title: "Focus Time",
            startHour: 9,
            startMinute: 0,
            endHour: 12,
            endMinute: 0,
            weekdayRawValues: [2, 3, 4, 5, 6]
        )
    }

    func addSchedule(
        title: String,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        weekdayRawValues: [Int]
    ) {
        guard let modelContext else { return }

        let schedule = DetoxScheduleRecord(
            title: title,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            weekdayRawValues: weekdayRawValues.sorted(),
            durationMinutes: Self.durationMinutes(
                startHour: startHour,
                startMinute: startMinute,
                endHour: endHour,
                endMinute: endMinute
            ),
            isEnabled: true
        )

        modelContext.insert(schedule)
        schedules.append(schedule)
        save()
        handleAdapterResult(deviceActivityAdapter.apply(schedule))
        loadSchedules()
    }

    func toggle(_ schedule: DetoxScheduleRecord, isEnabled: Bool) {
        schedule.isEnabled = isEnabled
        save()
        let result = isEnabled ? deviceActivityAdapter.apply(schedule) : deviceActivityAdapter.clear(schedule)
        handleAdapterResult(result)
        loadSchedules()
    }

    func delete(_ schedule: DetoxScheduleRecord) {
        handleAdapterResult(deviceActivityAdapter.clear(schedule))
        modelContext?.delete(schedule)
        schedules.removeAll { $0.id == schedule.id }
        save()
    }

    private func save() {
        do {
            try modelContext?.save()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Schedule changes could not be saved."
        }
    }

    private func handleAdapterResult(_ result: DeviceActivityScheduleAdapter.AdapterResult) {
        switch result {
        case .scheduled, .cleared:
            break
        case .failed(let message), .unavailable(let message):
            lastErrorMessage = message
        }
    }

    private static func durationMinutes(
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int
    ) -> Int {
        let start = startHour * 60 + startMinute
        let end = endHour * 60 + endMinute
        let sameDayDuration = end - start
        return sameDayDuration > 0 ? sameDayDuration : sameDayDuration + 24 * 60
    }
}

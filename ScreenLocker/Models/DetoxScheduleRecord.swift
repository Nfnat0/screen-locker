import Foundation
import SwiftData

@Model
final class DetoxScheduleRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var weekdayRawValues: [Int]
    var durationMinutes: Int
    var isEnabled: Bool
    var modeId: UUID?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        weekdayRawValues: [Int],
        durationMinutes: Int,
        isEnabled: Bool,
        modeId: UUID? = DetoxMode.defaultModeID,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.weekdayRawValues = weekdayRawValues
        self.durationMinutes = durationMinutes
        self.isEnabled = isEnabled
        self.modeId = modeId
        self.createdAt = createdAt
    }

    var timeRangeText: String {
        "\(Self.format(hour: startHour, minute: startMinute)) - \(Self.format(hour: endHour, minute: endMinute))"
    }

    var weekdayText: String {
        let symbols = Calendar.current.shortWeekdaySymbols
        return weekdayRawValues
            .sorted()
            .compactMap { value in
                guard value >= 1 && value <= symbols.count else { return nil }
                return symbols[value - 1]
            }
            .joined(separator: " ")
    }

    private static func format(hour: Int, minute: Int) -> String {
        let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}

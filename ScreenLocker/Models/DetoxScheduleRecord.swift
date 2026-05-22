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
    var isEnabled: Bool
    var modeId: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        weekdayRawValues: [Int],
        isEnabled: Bool = true,
        modeId: UUID? = DetoxMode.defaultModeID,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.weekdayRawValues = weekdayRawValues.sorted()
        self.isEnabled = isEnabled
        self.modeId = modeId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var durationMinutes: Int {
        let start = startHour * 60 + startMinute
        let end = endHour * 60 + endMinute
        let minutes = end >= start ? end - start : (24 * 60 - start) + end
        return max(1, minutes)
    }

    var timeRangeLabel: String {
        "\(Self.timeLabel(hour: startHour, minute: startMinute)) - \(Self.timeLabel(hour: endHour, minute: endMinute))"
    }

    var weekdaySummary: String {
        let values = Set(weekdayRawValues)
        if values == Set(1...7) {
            return "Every day"
        }

        let symbols = Calendar.current.shortWeekdaySymbols
        return weekdayRawValues.compactMap { value in
            guard (1...7).contains(value) else { return nil }
            return symbols[value - 1]
        }
        .joined(separator: " ")
    }

    private static func timeLabel(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let components = DateComponents(calendar: .current, hour: hour, minute: minute)
        return components.date.map(formatter.string(from:)) ?? "\(hour):\(String(format: "%02d", minute))"
    }
}

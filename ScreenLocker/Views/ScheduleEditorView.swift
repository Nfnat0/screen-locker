import SwiftUI

struct ScheduleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var scheduleManager: ScheduleManager

    @State private var title = "Focus Time"
    @State private var startDate = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var endDate = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @State private var selectedWeekdays: Set<Int> = [2, 3, 4, 5, 6]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Schedule name", text: $title)
                }

                Section("Time") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endDate, displayedComponents: .hourAndMinute)
                }

                Section("Days") {
                    ForEach(1...7, id: \.self) { weekday in
                        Toggle(Calendar.current.weekdaySymbols[weekday - 1], isOn: binding(for: weekday))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("New Schedule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedWeekdays.isEmpty
    }

    private func binding(for weekday: Int) -> Binding<Bool> {
        Binding(
            get: { selectedWeekdays.contains(weekday) },
            set: { isSelected in
                if isSelected {
                    selectedWeekdays.insert(weekday)
                } else {
                    selectedWeekdays.remove(weekday)
                }
            }
        )
    }

    private func save() {
        let calendar = Calendar.current
        let start = calendar.dateComponents([.hour, .minute], from: startDate)
        let end = calendar.dateComponents([.hour, .minute], from: endDate)

        scheduleManager.addSchedule(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            startHour: start.hour ?? 9,
            startMinute: start.minute ?? 0,
            endHour: end.hour ?? 12,
            endMinute: end.minute ?? 0,
            weekdayRawValues: Array(selectedWeekdays)
        )
    }
}

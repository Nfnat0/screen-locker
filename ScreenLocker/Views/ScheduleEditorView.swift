import SwiftUI

struct ScheduleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let schedule: DetoxScheduleRecord?
    let onSave: (DetoxScheduleDraft) -> Void

    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedWeekdays: Set<Int>
    @State private var isEnabled: Bool

    init(schedule: DetoxScheduleRecord? = nil, onSave: @escaping (DetoxScheduleDraft) -> Void) {
        self.schedule = schedule
        self.onSave = onSave

        _title = State(initialValue: schedule?.title ?? "Focus Time")
        _startDate = State(initialValue: Self.date(hour: schedule?.startHour ?? 9, minute: schedule?.startMinute ?? 0))
        _endDate = State(initialValue: Self.date(hour: schedule?.endHour ?? 12, minute: schedule?.endMinute ?? 0))
        _selectedWeekdays = State(initialValue: Set(schedule?.weekdayRawValues ?? [2, 3, 4, 5, 6]))
        _isEnabled = State(initialValue: schedule?.isEnabled ?? true)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Name")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.mutedText)

                        TextField("Schedule name", text: $title)
                            .textInputAutocapitalization(.words)
                            .foregroundStyle(AppTheme.primaryText)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.07))
                            )
                    }
                    .detoxCard()

                    VStack(spacing: 0) {
                        DatePicker("Start", selection: $startDate, displayedComponents: .hourAndMinute)
                            .tint(AppTheme.cyan)
                            .padding(.vertical, 12)

                        Divider().overlay(Color.white.opacity(0.08))

                        DatePicker("End", selection: $endDate, displayedComponents: .hourAndMinute)
                            .tint(AppTheme.cyan)
                            .padding(.vertical, 12)
                    }
                    .detoxCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Days")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.mutedText)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            ForEach(1...7, id: \.self) { weekday in
                                weekdayButton(weekday)
                            }
                        }
                    }
                    .detoxCard()

                    Toggle(isOn: $isEnabled) {
                        Label("Enable Schedule", systemImage: "calendar.badge.clock")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    .tint(AppTheme.cyan)
                    .detoxCard()

                    Text("Schedules are saved locally and registered through DeviceActivity when the entitlement is available. Weekday choices are preserved in Detox for the schedule foundation.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .padding(.bottom, 30)
            }
            .screenBackground()
            .navigationTitle(schedule == nil ? "New Schedule" : "Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.cyan)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .disabled(trimmedTitle.isEmpty || selectedWeekdays.isEmpty)
                    .foregroundStyle(AppTheme.cyan)
                }
            }
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func weekdayButton(_ weekday: Int) -> some View {
        let isSelected = selectedWeekdays.contains(weekday)

        return Button {
            if isSelected {
                selectedWeekdays.remove(weekday)
            } else {
                selectedWeekdays.insert(weekday)
            }
        } label: {
            Text(Calendar.current.shortWeekdaySymbols[weekday - 1])
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : AppTheme.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(Color.white.opacity(0.07)))
                )
        }
        .buttonStyle(.plain)
    }

    private func save() {
        let start = Calendar.current.dateComponents([.hour, .minute], from: startDate)
        let end = Calendar.current.dateComponents([.hour, .minute], from: endDate)
        let draft = DetoxScheduleDraft(
            title: trimmedTitle,
            startHour: start.hour ?? 9,
            startMinute: start.minute ?? 0,
            endHour: end.hour ?? 12,
            endMinute: end.minute ?? 0,
            weekdayRawValues: Array(selectedWeekdays).sorted(),
            isEnabled: isEnabled
        )
        onSave(draft)
        dismiss()
    }

    private static func date(hour: Int, minute: Int) -> Date {
        let components = DateComponents(calendar: .current, hour: hour, minute: minute)
        return components.date ?? Date()
    }
}

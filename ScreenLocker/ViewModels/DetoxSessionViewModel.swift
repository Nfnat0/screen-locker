import Foundation
import SwiftData

@MainActor
final class DetoxSessionViewModel: ObservableObject {
    @Published private(set) var sessions: [DetoxSessionRecord] = []
    @Published private(set) var activeSession: DetoxSessionRecord?
    @Published var now = Date()
    @Published var sessionError: String?

    private var modelContext: ModelContext?
    private weak var settingsStore: SettingsStore?
    private weak var appBlockingManager: AppBlockingManager?
    private var tickerTask: Task<Void, Never>?
    private var isConfigured = false

    deinit {
        tickerTask?.cancel()
    }

    func configure(
        modelContext: ModelContext,
        settingsStore: SettingsStore,
        appBlockingManager: AppBlockingManager
    ) {
        guard !isConfigured else { return }
        self.modelContext = modelContext
        self.settingsStore = settingsStore
        self.appBlockingManager = appBlockingManager
        isConfigured = true
        loadSessions()
        resumeActiveSessionIfNeeded()
        startTicker()
    }

    func loadSessions() {
        guard let modelContext else { return }

        do {
            let descriptor = FetchDescriptor<DetoxSessionRecord>(
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )
            sessions = try modelContext.fetch(descriptor)
        } catch {
            sessionError = "Sessions could not be loaded."
        }
    }

    func startSession(durationMinutes: Int? = nil) {
        guard activeSession == nil else { return }
        guard let modelContext, let settingsStore else {
            sessionError = "The session store is not ready yet."
            return
        }

        let minutes = max(1, durationMinutes ?? settingsStore.defaultDurationMinutes)
        let startDate = Date()
        let mode = DetoxMode.defaultMode(blockedAppCount: settingsStore.blockedAppCount)
        let record = DetoxSessionRecord(
            startDate: startDate,
            plannedEndDate: startDate.addingTimeInterval(TimeInterval(minutes * 60)),
            initialDurationMinutes: minutes,
            status: .active,
            modeId: mode.id,
            modeName: mode.name,
            blockedAppCount: mode.blockedAppCount
        )

        modelContext.insert(record)
        activeSession = record
        sessions.insert(record, at: 0)
        appBlockingManager?.applyBlocking(from: settingsStore)
        save()
        startTicker()
    }

    func extendActiveSession(by minutes: Int) {
        guard minutes > 0, let activeSession else { return }
        activeSession.extendedMinutes += minutes
        activeSession.plannedEndDate = activeSession.plannedEndDate.addingTimeInterval(TimeInterval(minutes * 60))
        now = Date()
        save()
    }

    func completeActiveSession() {
        guard let activeSession else { return }
        activeSession.status = .completed
        activeSession.actualEndDate = activeSession.plannedEndDate
        appBlockingManager?.clearBlocking()
        self.activeSession = nil
        save()
        loadSessions()
    }

    func breakActiveSession(reason: UnlockReason) {
        guard let activeSession else { return }
        activeSession.status = .broken
        activeSession.unlockReason = reason
        activeSession.actualEndDate = Date()
        appBlockingManager?.clearBlocking()
        self.activeSession = nil
        save()
        loadSessions()
    }

    func deleteAllSessions() {
        guard let modelContext else { return }
        for session in sessions {
            modelContext.delete(session)
        }
        sessions.removeAll()
        activeSession = nil
        save()
    }

    func stats(settingsStore: SettingsStore) -> DetoxStats {
        StatsCalculator.calculate(sessions: sessions, now: now)
    }

    private func resumeActiveSessionIfNeeded() {
        if let active = sessions.first(where: { $0.status == .active }) {
            if active.remainingTime(at: Date()) <= 0 {
                activeSession = active
                completeActiveSession()
            } else {
                activeSession = active
            }
        }
    }

    private func startTicker() {
        guard tickerTask == nil else { return }

        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.tick()
            }
        }
    }

    private func tick() {
        now = Date()

        guard let activeSession else { return }
        if activeSession.remainingTime(at: now) <= 0 {
            completeActiveSession()
        }
    }

    private func save() {
        do {
            try modelContext?.save()
        } catch {
            sessionError = "Your latest session change could not be saved."
        }
    }
}

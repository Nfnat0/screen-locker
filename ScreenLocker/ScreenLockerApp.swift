import SwiftData
import SwiftUI

@main
struct ScreenLockerApp: App {
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var appBlockingManager = AppBlockingManager()
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var sessionViewModel = DetoxSessionViewModel()
    @StateObject private var scheduleManager = ScheduleManager()

    private let modelContainer: ModelContainer = {
        let schema = Schema([DetoxSessionRecord.self, DetoxScheduleRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create SwiftData container: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settingsStore)
                .environmentObject(appBlockingManager)
                .environmentObject(purchaseManager)
                .environmentObject(sessionViewModel)
                .environmentObject(scheduleManager)
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
                .tint(AppTheme.cyan)
        }
    }
}

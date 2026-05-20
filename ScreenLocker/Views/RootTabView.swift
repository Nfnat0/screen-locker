import SwiftData
import SwiftUI

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var appBlockingManager: AppBlockingManager
    @EnvironmentObject private var sessionViewModel: DetoxSessionViewModel

    var body: some View {
        TabView {
            NavigationStack {
                TimerView()
            }
            .tabItem {
                Label("Timer", systemImage: "timer")
            }

            NavigationStack {
                InsightsView()
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .task {
            sessionViewModel.configure(
                modelContext: modelContext,
                settingsStore: settingsStore,
                appBlockingManager: appBlockingManager
            )
        }
        .fullScreenCover(isPresented: activeSessionBinding) {
            if let session = sessionViewModel.activeSession {
                LockScreenView(session: session)
                    .interactiveDismissDisabled()
            }
        }
        .alert("Session Issue", isPresented: sessionErrorBinding) {
            Button("OK") {
                sessionViewModel.sessionError = nil
            }
        } message: {
            Text(sessionViewModel.sessionError ?? "")
        }
    }

    private var activeSessionBinding: Binding<Bool> {
        Binding(
            get: { sessionViewModel.activeSession != nil },
            set: { _ in }
        )
    }

    private var sessionErrorBinding: Binding<Bool> {
        Binding(
            get: { sessionViewModel.sessionError != nil },
            set: { isPresented in
                if !isPresented {
                    sessionViewModel.sessionError = nil
                }
            }
        )
    }
}

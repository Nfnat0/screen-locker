# Codex Handoff

This document is the working handoff for future Codex sessions in this repo.

## Current Status

The repository now contains a buildable SwiftUI iOS MVP plus the first product-hardening and Pro foundation pass for the digital detox timer app described in `docs/digital_detox_timer_codex_plan.md`.

Implemented:

- Native SwiftUI iOS app in `ScreenLocker.xcodeproj`.
- Dark, minimal Timer / Insights / Settings tab UI.
- Local detox session timer with active lock screen.
- Extend flow with `+5`, `+15`, `+30`, and custom minutes.
- Intentional unlock flow with countdown, reason selection, and broken-session recording.
- SwiftData persistence for detox sessions.
- UserDefaults-backed settings for duration, unlock delay, blocked app count, appearance, notifications, and local Pro unlock cache.
- Statistics calculation from persisted sessions.
- Screen Time API abstraction with FamilyControls / ManagedSettings guards and fallback behavior.
- Reusable Screen Time status UI with explicit authorization and shielding fallback messages.
- `ShieldingResult` return values from `AppBlockingManager.applyBlocking(from:)`.
- XCTest target with coverage for statistics and session computed values.
- StoreKit 2 purchase manager foundation with verified entitlement refresh and simulator/local fallback unlock when no product is configured.
- SwiftData-backed Pro schedule model, schedule manager, and schedule editor UI.
- Guarded `DeviceActivityScheduleAdapter` behind `ScheduleManager`.
- Generated 1024 x 1024 app icon artwork installed in the asset catalog.
- Pro placeholder structure for modes, Deep Lock, advanced insights, themes, widgets, Live Activity, reflection log, and export.
- Deep Lock guided setup screen with careful non-absolute wording.

Last verified:

- Xcode 26.5.
- iPhone 17 simulator.
- `session_show_defaults` via XcodeBuildMCP confirmed project `ScreenLocker.xcodeproj`, scheme `ScreenLocker`, configuration `Debug`, simulator `iPhone 17`.
- `build_sim extraArgs=["CODE_SIGNING_ALLOWED=NO"]` via XcodeBuildMCP succeeded with 0 warnings and 0 errors.
- `xcodebuild -project ScreenLocker.xcodeproj -scheme ScreenLocker -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO test` succeeded with 6 tests, 0 failures.
- `build_run_sim extraArgs=["CODE_SIGNING_ALLOWED=NO"]` via XcodeBuildMCP succeeded and launched the app.
- Manual smoke check covered app launch, Timer, Screen Time fallback start, active lock screen, `+5 min` extend, unlock long press, unlock delay countdown, broken session recording, Insights stats with broken/extended values, Settings -> Blocked Apps status, StoreKit unavailable local Pro unlock, Settings -> Schedules creation and persistence across relaunch, Deep Lock wording, and app icon presence on the simulator Home Screen.

## Project Structure

```text
ScreenLocker.xcodeproj/
  project.pbxproj

ScreenLocker/
  ScreenLockerApp.swift
  Assets.xcassets/
  Components/
  Models/
  Services/
  Theme/
  ViewModels/
  Views/

ScreenLockerTests/

docs/
  digital_detox_timer_codex_plan.md
  codex_handoff.md
  screen_time_setup_notes.md
```

Important files:

- `ScreenLocker/ScreenLockerApp.swift`: app entry point, environment objects, SwiftData container.
- `ScreenLocker/Views/RootTabView.swift`: bottom tabs and active-session full-screen presentation.
- `ScreenLocker/ViewModels/DetoxSessionViewModel.swift`: session lifecycle, ticker, persistence, completion/break handling.
- `ScreenLocker/Services/AppBlockingManager.swift`: Screen Time authorization and shielding abstraction.
- `ScreenLocker/Services/DeviceActivityScheduleAdapter.swift`: guarded DeviceActivity bridge for Pro schedule monitoring.
- `ScreenLocker/Services/PurchaseManager.swift`: StoreKit 2 product loading, purchase, restore, entitlement refresh, and local fallback unlock.
- `ScreenLocker/Services/ScheduleManager.swift`: SwiftData schedule loading, creation, toggle/delete, and DeviceActivity coordination.
- `ScreenLocker/Services/SettingsStore.swift`: local settings and FamilyActivitySelection persistence.
- `ScreenLocker/Services/StatsCalculator.swift`: all derived statistics.
- `ScreenLocker/Models/BlockingAuthorizationState.swift`: Screen Time authorization display model.
- `ScreenLocker/Models/DetoxScheduleRecord.swift`: SwiftData model for Pro schedules.
- `ScreenLocker/Models/ProProduct.swift`: StoreKit product identifiers.
- `ScreenLocker/Models/ShieldingResult.swift`: value type describing app-shielding outcomes.
- `ScreenLocker/Views/TimerView.swift`: Timer tab and session start flow.
- `ScreenLocker/Views/LockScreenView.swift`: active lock screen.
- `ScreenLocker/Views/UnlockRequestView.swift`: deliberate unlock flow.
- `ScreenLocker/Views/InsightsView.swift`: stats overview.
- `ScreenLocker/Views/SettingsView.swift`: settings navigation.
- `ScreenLocker/Views/BlockedAppsView.swift`: Screen Time picker/fallback UI.
- `ScreenLocker/Views/ProViews.swift`: Pro, modes, schedules, Deep Lock, and advanced insights placeholders.
- `ScreenLocker/Views/ScheduleEditorView.swift`: Pro schedule creation form.
- `ScreenLocker/Views/ScreenTimeStatusView.swift`: reusable authorization/shielding status card.
- `ScreenLocker/Theme/DesignSystem.swift`: colors, card styling, and formatting helpers.
- `ScreenLockerTests/StatsCalculatorTests.swift`: unit tests for stats aggregation and edge cases.
- `ScreenLockerTests/DetoxSessionRecordTests.swift`: unit tests for session computed values.

## Architecture Notes

The app is intentionally small and direct:

- SwiftUI views are in `Views/`.
- Reusable UI pieces are in `Components/`.
- Business logic is in `ViewModels/` and `Services/`.
- Persistent domain objects and enums are in `Models/`.
- Styling tokens and formatting helpers live in `Theme/`.

State flow:

1. `ScreenLockerApp` creates `SettingsStore`, `AppBlockingManager`, `PurchaseManager`, and `DetoxSessionViewModel`.
2. `ScreenLockerApp` also creates `ScheduleManager` and includes `DetoxScheduleRecord` in the SwiftData schema.
3. `RootTabView` configures `DetoxSessionViewModel` and `ScheduleManager` with the SwiftData `ModelContext`.
4. `TimerView` starts a session.
5. `DetoxSessionViewModel` inserts a `DetoxSessionRecord`, starts ticking, and asks `AppBlockingManager` to apply shields.
6. `RootTabView` presents `LockScreenView` while `activeSession` exists.
7. Completion or early unlock clears shielding and updates the persisted session.
8. `InsightsView` derives stats through `StatsCalculator`.
9. `SchedulesView` reads persisted schedules through `ScheduleManager`; schedule enable/disable and delete operations call the guarded DeviceActivity adapter.

## Data Model

`DetoxSessionRecord` is a SwiftData `@Model`.

`DetoxScheduleRecord` is a SwiftData `@Model`.

Persisted session fields include:

- `id`
- `startDate`
- `plannedEndDate`
- `actualEndDate`
- `initialDurationMinutes`
- `extendedMinutes`
- `statusRawValue`
- `unlockReasonRawValue`
- `modeId`
- `modeName`
- `blockedAppCount`

Settings are currently persisted in `UserDefaults` through `SettingsStore`.

Pro unlock state is persisted in `UserDefaults` through `PurchaseManager`, with StoreKit entitlement refresh layered on top.

## Build And Run

Prefer XcodeBuildMCP for simulator work.

Current XcodeBuildMCP defaults are configured in `.xcodebuildmcp/config.yaml`:

- Project: `ScreenLocker.xcodeproj`
- Scheme: `ScreenLocker`
- Configuration: `Debug`
- Simulator: `iPhone 17`
- Bundle ID: `com.example.ScreenLocker`

Typical verification:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

When using XcodeBuildMCP, call `session_show_defaults` first, then `build_sim`.

The current Xcode target build setting still uses `PRODUCT_BUNDLE_IDENTIFIER = com.Nfnat0.ScreenLocker`. The XcodeBuildMCP default profile reports `com.example.ScreenLocker`, so `build_run_sim` works reliably for launch/install, but direct `launch_app_sim` may target a stale simulator app unless the actual built bundle ID is used. The bundle ID was not changed in this pass.

## Known Limitations

- Screen Time APIs require Apple Developer entitlement setup and cannot be fully validated by a plain simulator smoke test.
- The app currently falls back to local timer behavior when Screen Time authorization or shielding is unavailable.
- StoreKit product IDs are placeholders and no StoreKit configuration file is included. In simulator/demo builds with no returned product, `PurchaseManager` locally unlocks Pro and explains why.
- DeviceActivity scheduling is isolated behind `DeviceActivityScheduleAdapter`, but entitlement-backed monitoring and monitor-extension behavior still need physical-device validation.
- Schedule weekday selections are persisted and shown in UI; richer weekday-specific DeviceActivity behavior should be validated during entitlement/device work.
- Widgets, Live Activity, reflection log, export, and custom themes are placeholders.

## Good Next Tasks

- Align the Xcode target bundle ID and `.xcodebuildmcp/config.yaml` bundle ID once the intended app identifier is confirmed.
- Add a StoreKit configuration file and production product IDs when App Store Connect setup is ready.
- Validate FamilyControls, ManagedSettings, and DeviceActivity behavior on a physical device with the required entitlements.
- Add a DeviceActivity monitor extension if schedules need to trigger shielding outside the foreground app.
- Improve app selection copy once Family Controls is tested on a real device.
- Add UI tests for start / extend / unlock / stats update.
- Review SwiftData migration strategy before changing `DetoxSessionRecord`.
- Add tests for `ScheduleManager` and StoreKit entitlement state if these services gain injectable dependencies.

## Editing Guidance

- Keep changes small and SwiftUI-native.
- Avoid adding third-party dependencies.
- Keep Screen Time claims careful: say "reduce common escape routes", "guide to set up via Screen Time", and "add an extra layer of protection".
- Do not claim the app can absolutely prevent uninstalling or bypassing.
- If architecture, setup, or implementation status changes, update this document and `AGENTS.md`.

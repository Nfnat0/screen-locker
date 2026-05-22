# Codex Handoff

This document is the working handoff for future Codex sessions in this repo.

## Current Status

The repository now contains a buildable SwiftUI iOS MVP for the digital detox timer app described in `docs/digital_detox_timer_codex_plan.md`.

Implemented:

- Native SwiftUI iOS app in `ScreenLocker.xcodeproj`.
- Dark, minimal Timer / Insights / Settings tab UI.
- Local detox session timer with active lock screen.
- Extend flow with `+5`, `+15`, `+30`, and custom minutes.
- Intentional unlock flow with countdown, reason selection, and broken-session recording.
- SwiftData persistence for detox sessions.
- UserDefaults-backed settings for duration, unlock delay, blocked app count, appearance, notifications, and Pro placeholder state.
- Statistics calculation from persisted sessions.
- Screen Time API abstraction with FamilyControls / ManagedSettings guards and fallback behavior.
- Shared Screen Time status/result models and reusable fallback status UI.
- StoreKit 2 Pro foundation with product loading, purchase, restore, verified entitlement refresh, and local demo unlock fallback.
- SwiftData-backed Pro schedule model, schedule editor UI, schedule manager, and guarded DeviceActivity adapter.
- XCTest target with focused coverage for statistics and session computed values.
- Pro placeholder structure for modes, Deep Lock, advanced insights, themes, widgets, Live Activity, reflection log, and export.
- Deep Lock guided setup screen with careful non-absolute wording.

Last verified:

- Xcode 26.5.
- iPhone 17 simulator.
- `build_sim` via XcodeBuildMCP with `CODE_SIGNING_ALLOWED=NO`.
- `xcodebuild -project ScreenLocker.xcodeproj -scheme ScreenLocker -configuration Debug -destination 'platform=iOS Simulator,id=646B4A11-CB3E-4CF4-B17B-7735990FDDB8' CODE_SIGNING_ALLOWED=NO test -quiet`.
- Build succeeded with 0 warnings and 0 errors.
- Unit tests passed: 6 tests across `StatsCalculatorTests` and `DetoxSessionRecordTests`.
- Manual smoke check covered app launch, Timer, fallback start, active lock screen, extend, unlock countdown, broken session, Insights stats, Settings, and Deep Lock setup.

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

docs/
  digital_detox_timer_codex_plan.md
  codex_handoff.md
  screen_time_setup_notes.md
  superpowers/plans/2026-05-21-product-hardening-pro-foundation.md

ScreenLockerTests/
  StatsCalculatorTests.swift
  DetoxSessionRecordTests.swift
```

Important files:

- `ScreenLocker/ScreenLockerApp.swift`: app entry point, environment objects, SwiftData container.
- `ScreenLocker/Views/RootTabView.swift`: bottom tabs and active-session full-screen presentation.
- `ScreenLocker/ViewModels/DetoxSessionViewModel.swift`: session lifecycle, ticker, persistence, completion/break handling.
- `ScreenLocker/Services/AppBlockingManager.swift`: Screen Time authorization and shielding abstraction.
- `ScreenLocker/Models/BlockingAuthorizationState.swift`: authorization display state.
- `ScreenLocker/Models/ShieldingResult.swift`: shielding outcome value type.
- `ScreenLocker/Services/SettingsStore.swift`: local settings and FamilyActivitySelection persistence.
- `ScreenLocker/Services/StatsCalculator.swift`: all derived statistics.
- `ScreenLocker/Models/ProProduct.swift`: StoreKit product identifiers and fallback display metadata.
- `ScreenLocker/Services/PurchaseManager.swift`: StoreKit 2 purchase, restore, entitlement refresh, and demo fallback.
- `ScreenLocker/Models/DetoxScheduleRecord.swift`: SwiftData schedule model.
- `ScreenLocker/Services/ScheduleManager.swift`: schedule persistence and monitoring coordination.
- `ScreenLocker/Services/DeviceActivityScheduleAdapter.swift`: guarded DeviceActivity bridge.
- `ScreenLocker/Views/TimerView.swift`: Timer tab and session start flow.
- `ScreenLocker/Views/LockScreenView.swift`: active lock screen.
- `ScreenLocker/Views/UnlockRequestView.swift`: deliberate unlock flow.
- `ScreenLocker/Views/InsightsView.swift`: stats overview.
- `ScreenLocker/Views/SettingsView.swift`: settings navigation.
- `ScreenLocker/Views/BlockedAppsView.swift`: Screen Time picker/fallback UI.
- `ScreenLocker/Views/ScreenTimeStatusView.swift`: reusable Screen Time status card.
- `ScreenLocker/Views/ProViews.swift`: Pro, modes, schedules, Deep Lock, and advanced insights placeholders.
- `ScreenLocker/Views/ScheduleEditorView.swift`: schedule create/edit sheet.
- `ScreenLocker/Theme/DesignSystem.swift`: colors, card styling, and formatting helpers.

## Architecture Notes

The app is intentionally small and direct:

- SwiftUI views are in `Views/`.
- Reusable UI pieces are in `Components/`.
- Business logic is in `ViewModels/` and `Services/`.
- Persistent domain objects and enums are in `Models/`.
- Styling tokens and formatting helpers live in `Theme/`.

State flow:

1. `ScreenLockerApp` creates `SettingsStore`, `AppBlockingManager`, `PurchaseManager`, and `DetoxSessionViewModel`.
   It also creates `ScheduleManager` and includes `DetoxScheduleRecord` in the SwiftData schema.
2. `RootTabView` configures `DetoxSessionViewModel` with the SwiftData `ModelContext`.
   It configures `ScheduleManager` with the same context.
3. `TimerView` starts a session.
4. `DetoxSessionViewModel` inserts a `DetoxSessionRecord`, starts ticking, and asks `AppBlockingManager` to apply shields.
5. `RootTabView` presents `LockScreenView` while `activeSession` exists.
6. Completion or early unlock clears shielding and updates the persisted session.
7. `InsightsView` derives stats through `StatsCalculator`.

## Data Model

`DetoxSessionRecord` is a SwiftData `@Model`.

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

`DetoxScheduleRecord` is a SwiftData `@Model`.

Persisted schedule fields include:

- `id`
- `title`
- `startHour`
- `startMinute`
- `endHour`
- `endMinute`
- `weekdayRawValues`
- `isEnabled`
- `modeId`
- `createdAt`
- `updatedAt`

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

For tests, the most reliable verified command in the current environment is:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=646B4A11-CB3E-4CF4-B17B-7735990FDDB8' \
  CODE_SIGNING_ALLOWED=NO \
  test -quiet
```

The app uses an in-memory SwiftData container while XCTest is running so hosted unit tests do not touch or migrate a local app store.

## Known Limitations

- Screen Time APIs require Apple Developer entitlement setup and cannot be fully validated by a plain simulator smoke test.
- The app currently falls back to local timer behavior when Screen Time authorization or shielding is unavailable.
- StoreKit 2 code is wired, but real purchase validation still requires App Store Connect product setup or a StoreKit configuration file. The development fallback can locally unlock Pro.
- DeviceActivity scheduling is guarded behind `DeviceActivityScheduleAdapter`; full behavior still requires entitlement setup and real-device testing.
- Schedule weekday choices are persisted in the app model. The current DeviceActivity adapter registers a repeating time window and should be expanded after entitlement/device validation if per-weekday system monitoring is required.
- Widgets, Live Activity, reflection log, export, and custom themes are placeholders.
- App icon assets exist as placeholders, not final artwork.

## Good Next Tasks

- Add app icon artwork.
- Add StoreKit 2 product IDs and transaction verification.
- Add a StoreKit configuration file for simulator purchase QA.
- Validate DeviceActivity schedule registration on a physical entitlement-enabled device.
- Improve app selection copy once Family Controls is tested on a real device.
- Add UI tests for start / extend / unlock / stats update.
- Review SwiftData migration strategy before changing persisted models again.

## Editing Guidance

- Keep changes small and SwiftUI-native.
- Avoid adding third-party dependencies.
- Keep Screen Time claims careful: say "reduce common escape routes", "guide to set up via Screen Time", and "add an extra layer of protection".
- Do not claim the app can absolutely prevent uninstalling or bypassing.
- If architecture, setup, or implementation status changes, update this document and `AGENTS.md`.

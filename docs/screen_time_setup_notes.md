# Screen Time Setup Notes

This project includes Screen Time integration code behind `AppBlockingManager`, but full behavior depends on Apple entitlement and account configuration.

## Current Implementation

Files:

- `ScreenLocker/Services/AppBlockingManager.swift`
- `ScreenLocker/Services/DeviceActivityScheduleAdapter.swift`
- `ScreenLocker/Services/ScheduleManager.swift`
- `ScreenLocker/Services/SettingsStore.swift`
- `ScreenLocker/Views/BlockedAppsView.swift`
- `ScreenLocker/Views/ScreenTimeStatusView.swift`

Frameworks used when available:

- `FamilyControls`
- `ManagedSettings`
- `DeviceActivity`

Implemented behavior:

- Request Family Controls authorization with `AuthorizationCenter.shared.requestAuthorization(for: .individual)`.
- Show `FamilyActivityPicker` for selecting apps, categories, and web domains.
- Persist `FamilyActivitySelection` through `SettingsStore`.
- Apply ManagedSettings shields during active sessions.
- Clear all ManagedSettings shields when a session completes or breaks.
- Persist Pro schedule records and route schedule enable/disable/delete through a guarded DeviceActivity adapter.
- Fall back to local timer behavior with a visible warning when authorization or entitlement setup is unavailable.

## Required Manual Configuration

Before expecting real app shielding to work:

1. Use a real Apple Developer account.
2. Enable the required Family Controls / Screen Time capabilities for the app identifier.
3. Add the required entitlements in Xcode.
4. Keep bundle identifier and signing settings aligned with the entitlement-enabled app identifier.
5. Test on a physical device where possible; simulator behavior may be limited.

Do not commit signing credentials, provisioning profiles, App Store Connect keys, or secrets.

## Product Wording Rules

Deep Lock and Screen Time copy must stay careful:

- Good: "Guide to set up via Screen Time"
- Good: "Reduce common escape routes"
- Good: "Add an extra layer of protection"
- Avoid: any claim that the app absolutely prevents uninstalling, bypassing, or disabling.

Current Deep Lock wording intentionally says:

> Deep Lock helps you stay committed by reducing common escape routes.

## Future Implementation Notes

Potential next steps:

- Add an entitlement-backed build configuration after the Apple Developer setup is complete.
- Test `FamilyActivityPicker` selection persistence on device.
- Confirm shield clearing on completion, early unlock, and app relaunch.
- Validate DeviceActivity monitoring for Pro schedules on a physical device.
- Add UI states for approved / denied / restricted / unavailable authorization outcomes.
- Consider adding a debug-only "clear shields" button if testing leaves shields active.

## DeviceActivity Scheduling Notes

The schedule foundation uses `DeviceActivityScheduleAdapter` to keep DeviceActivity calls isolated from SwiftUI screens.

The current adapter starts or clears a guarded repeating DeviceActivity interval for each enabled schedule. Schedule weekday selections are persisted and shown in the app UI; entitlement-backed testing should confirm the final weekday-specific monitoring strategy before relying on recurring schedule behavior in production.

Manual setup required before real scheduled monitoring is expected:

1. Confirm DeviceActivity capability and related entitlements in the Apple Developer account.
2. Add any required DeviceActivity monitor extension target if schedule callbacks need to trigger shielding outside the foreground app.
3. Test on a physical device with Screen Time authorization approved.
4. Confirm schedules are cleared when users disable a schedule or delete it.

The app must continue to show a clear unavailable/fallback message when DeviceActivity cannot start monitoring.

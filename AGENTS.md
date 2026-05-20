# Project instructions for Codex

This is an iOS app project.

## Current project

- App project: `ScreenLocker.xcodeproj`
- Scheme: `ScreenLocker`
- Bundle ID: `com.example.ScreenLocker`
- Primary app source: `ScreenLocker/`
- Product: dark, minimal SwiftUI digital detox timer app.
- Target style: iPhone-first, iOS 17+, SwiftUI, SwiftData, Swift Concurrency.

## Required project references

Read these before substantial implementation work:

- `docs/codex_handoff.md` — current implementation status, architecture, structure, verification history, known limitations, and next tasks.
- `docs/screen_time_setup_notes.md` — Screen Time / FamilyControls / ManagedSettings setup notes and wording constraints.
- `docs/superpowers/plans/2026-05-21-product-hardening-pro-foundation.md` — next implementation plan for tests, Screen Time hardening, StoreKit, and schedule foundation.
- `docs/digital_detox_timer_codex_plan.md` — original product and implementation plan.

## Scope

- Treat this repository as an isolated iOS project.
- Work only inside this repository unless explicitly asked.
- Do not read or modify files outside this repository.
- Prefer Swift, SwiftUI, Swift Concurrency, and Apple platform conventions.
- Keep changes small, focused, and reviewable.
- Avoid introducing third-party dependencies unless explicitly approved.
- Preserve the dark, minimal, chic UI direction.
- Keep business logic out of views where practical; prefer `Services/` and `ViewModels/`.
- Update `docs/codex_handoff.md` when changing project structure, architecture, verification status, or known limitations.

## Project structure

- `ScreenLocker/ScreenLockerApp.swift` — app entry point, environment objects, SwiftData container.
- `ScreenLocker/Models/` — SwiftData model and domain enums/structs.
- `ScreenLocker/Services/` — settings, stats, app blocking, purchase placeholder services.
- `ScreenLocker/ViewModels/` — session lifecycle and timer coordination.
- `ScreenLocker/Views/` — screens and navigation.
- `ScreenLocker/Components/` — reusable SwiftUI components.
- `ScreenLocker/Theme/` — design tokens and formatting helpers.
- `docs/` — implementation plan and Codex handoff docs.

## Build and test

- Use XcodeBuildMCP when available.
- XcodeBuildMCP defaults should point to `ScreenLocker.xcodeproj`, scheme `ScreenLocker`, simulator `iPhone 17`.
- Prefer simulator builds before making broad changes.
- After modifying Swift code, run the smallest useful build or test.
- Report build failures with the exact command, file, line, and likely cause when available.
- If XcodeBuildMCP is unavailable, a useful fallback is:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Screen Time and Pro features

- Keep Screen Time API code behind `AppBlockingManager` or a similar abstraction.
- The app must remain buildable when Screen Time entitlement/configuration is incomplete.
- Use fallback UI/behavior for simulator or entitlement-limited builds.
- Do not claim the app can absolutely prevent uninstalling, bypassing, or disabling.
- Preferred wording: "Guide to set up via Screen Time", "Reduce common escape routes", and "Add an extra layer of protection".
- StoreKit, schedules, widgets, Live Activity, reflection log, export stats, and custom themes are currently placeholder Pro structures unless explicitly implemented later.
- For app icon raster artwork, use the `imagegen` skill and move the selected generated asset into `ScreenLocker/Assets.xcassets/AppIcon.appiconset/`.

## Safety

- Do not access signing credentials, provisioning profiles, App Store Connect keys, fastlane secrets, or .env files unless explicitly asked.
- Do not change bundle identifiers, team IDs, signing settings, entitlements, or deployment targets unless explicitly asked.
- Do not run destructive cleanup commands unless explicitly asked.

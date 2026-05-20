# Project instructions for Gemini

This is an iOS app project.

## Scope

- Treat this repository as an isolated iOS project.
- Work only inside this repository unless explicitly asked.
- Do not read or modify files outside this repository.
- Prefer Swift, SwiftUI, Swift Concurrency, and Apple platform conventions.
- Keep changes small, focused, and reviewable.
- Avoid introducing third-party dependencies unless explicitly approved.

## Build and test

- Use XcodeBuildMCP when available.
- Prefer simulator builds before making broad changes.
- After modifying Swift code, run the smallest useful build or test.
- Report build failures with the exact command, file, line, and likely cause when available.

## Safety

- Do not access signing credentials, provisioning profiles, App Store Connect keys, fastlane secrets, or .env files unless explicitly asked.
- Do not change bundle identifiers, team IDs, signing settings, entitlements, or deployment targets unless explicitly asked.
- Do not run destructive cleanup commands unless explicitly asked.

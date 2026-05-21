# Product Hardening And Pro Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current MVP into a better-tested, entitlement-ready, Pro-ready app foundation without expanding into widgets, Live Activity, or export features yet.

**Architecture:** Keep the existing SwiftUI structure and add the smallest useful production seams: XCTest coverage for pure logic, richer Screen Time state reporting, StoreKit 2 purchase infrastructure, and persisted schedule models. Screen Time and DeviceActivity remain behind services so the app still builds and runs when entitlements are not configured.

**Tech Stack:** SwiftUI, SwiftData, XCTest, StoreKit 2, FamilyControls, ManagedSettings, DeviceActivity, XcodeBuildMCP.

---

## Scope

This plan covers the next implementation pass after the MVP:

- Add automated tests for statistics and session edge cases.
- Make Screen Time authorization/shielding states easier to diagnose.
- Replace the local-only Pro unlock with StoreKit 2 infrastructure that still supports simulator/demo fallback.
- Add persisted schedule models and schedule UI editing, with DeviceActivity integration behind a guarded adapter.
- Generate final app icon artwork with the `imagegen` skill and install it into the asset catalog.
- Update documentation and run final verification.

This plan does not implement widgets, Live Activity, reflection log, export stats, or custom themes. Those should be separate plans after this foundation is stable.

## File Structure

Create:

- `ScreenLockerTests/StatsCalculatorTests.swift`: unit tests for protected time, completion rate, streaks, weekly aggregation, broken sessions, and extensions.
- `ScreenLockerTests/DetoxSessionRecordTests.swift`: unit tests for computed session properties.
- `ScreenLocker/Models/BlockingAuthorizationState.swift`: move and expand blocking authorization display state.
- `ScreenLocker/Models/ShieldingResult.swift`: value type describing shielding outcomes.
- `ScreenLocker/Models/ProProduct.swift`: StoreKit product identifiers and display metadata.
- `ScreenLocker/Models/DetoxScheduleRecord.swift`: persisted schedule model.
- `ScreenLocker/Services/ScheduleManager.swift`: schedule persistence, enable/disable, and activation coordination.
- `ScreenLocker/Services/DeviceActivityScheduleAdapter.swift`: guarded DeviceActivity bridge.
- `ScreenLocker/Views/ScreenTimeStatusView.swift`: reusable authorization and shielding status UI.
- `ScreenLocker/Views/ScheduleEditorView.swift`: schedule creation/editing screen.
- `tmp/imagegen/`: temporary workspace for generated app icon candidates.
- `ScreenLocker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`: selected generated app icon artwork.

Modify:

- `ScreenLocker.xcodeproj/project.pbxproj`: add XCTest target, test files, and new source files.
- `ScreenLocker/ScreenLockerApp.swift`: include `DetoxScheduleRecord` in the SwiftData schema.
- `ScreenLocker/Services/AppBlockingManager.swift`: return `ShieldingResult`, expose richer status, and keep clear-shield behavior explicit.
- `ScreenLocker/Services/PurchaseManager.swift`: replace placeholder-only purchase logic with StoreKit 2 loading, purchase, restore, and verified entitlement refresh.
- `ScreenLocker/Services/SettingsStore.swift`: keep fallback behavior and avoid using StoreKit state here.
- `ScreenLocker/Views/BlockedAppsView.swift`: use `ScreenTimeStatusView`.
- `ScreenLocker/Views/TimerView.swift`: show clearer Screen Time fallback state.
- `ScreenLocker/Views/ProViews.swift`: wire Pro button to async StoreKit purchase flow and use `ScheduleEditorView`.
- `docs/codex_handoff.md`: record new status, test coverage, and limitations.
- `docs/screen_time_setup_notes.md`: add DeviceActivity setup notes after schedule adapter work.

## Verification Commands

Use XcodeBuildMCP when available:

```text
session_show_defaults
build_sim extraArgs=["CODE_SIGNING_ALLOWED=NO"]
test_sim extraArgs=["CODE_SIGNING_ALLOWED=NO"]
```

Fallback shell commands:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

---

### Task 1: Add XCTest Target And Stats Tests

**Files:**
- Modify: `ScreenLocker.xcodeproj/project.pbxproj`
- Create: `ScreenLockerTests/StatsCalculatorTests.swift`
- Create: `ScreenLockerTests/DetoxSessionRecordTests.swift`

- [ ] **Step 1: Add the test target shell**

Add an iOS Unit Testing Bundle target named `ScreenLockerTests` to `ScreenLocker.xcodeproj`.

Required build settings:

```text
PRODUCT_BUNDLE_IDENTIFIER = com.example.ScreenLockerTests
PRODUCT_NAME = ScreenLockerTests
TEST_HOST = $(BUILT_PRODUCTS_DIR)/ScreenLocker.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/ScreenLocker
BUNDLE_LOADER = $(TEST_HOST)
SWIFT_VERSION = 5.0
IPHONEOS_DEPLOYMENT_TARGET = 17.0
```

Add `StatsCalculatorTests.swift` and `DetoxSessionRecordTests.swift` to the test target only.

- [ ] **Step 2: Verify the empty test target builds**

Run:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Expected: the test action runs and reports 0 tests or only scaffold tests.

- [ ] **Step 3: Add `StatsCalculatorTests.swift`**

Create `ScreenLockerTests/StatsCalculatorTests.swift`:

```swift
import XCTest
@testable import ScreenLocker

final class StatsCalculatorTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testCalculateCountsTodayProtectedTimeFromCompletedAndBrokenSessions() throws {
        let now = try makeDate(year: 2026, month: 5, day: 21, hour: 12, minute: 0)
        let completedStart = try makeDate(year: 2026, month: 5, day: 21, hour: 9, minute: 0)
        let brokenStart = try makeDate(year: 2026, month: 5, day: 21, hour: 11, minute: 0)
        let yesterdayStart = try makeDate(year: 2026, month: 5, day: 20, hour: 9, minute: 0)

        let sessions = [
            makeSession(start: completedStart, plannedMinutes: 60, actualMinutes: 60, status: .completed),
            makeSession(start: brokenStart, plannedMinutes: 60, actualMinutes: 15, status: .broken, reason: .changedMind),
            makeSession(start: yesterdayStart, plannedMinutes: 45, actualMinutes: 45, status: .completed)
        ]

        let stats = StatsCalculator.calculate(sessions: sessions, now: now, calendar: calendar)

        XCTAssertEqual(stats.protectedTimeToday, 75 * 60, accuracy: 0.1)
        XCTAssertEqual(stats.protectedTimeAllTime, 120 * 60, accuracy: 0.1)
        XCTAssertEqual(stats.sessionCountToday, 2)
        XCTAssertEqual(stats.brokenSessionCount, 1)
        XCTAssertEqual(stats.completionRate, 2.0 / 3.0, accuracy: 0.001)
    }

    func testCalculateWeeklyProtectedTimeAggregatesByDay() throws {
        let now = try makeDate(year: 2026, month: 5, day: 21, hour: 12, minute: 0)
        let monday = try makeDate(year: 2026, month: 5, day: 18, hour: 8, minute: 0)
        let thursday = try makeDate(year: 2026, month: 5, day: 21, hour: 8, minute: 0)

        let sessions = [
            makeSession(start: monday, plannedMinutes: 30, actualMinutes: 30, status: .completed),
            makeSession(start: thursday, plannedMinutes: 90, actualMinutes: 90, status: .completed)
        ]

        let stats = StatsCalculator.calculate(sessions: sessions, now: now, calendar: calendar)

        XCTAssertEqual(stats.weeklyProtectedTime.count, 7)
        XCTAssertEqual(stats.weeklyProtectedTime[0].protectedSeconds, 30 * 60, accuracy: 0.1)
        XCTAssertEqual(stats.weeklyProtectedTime[3].protectedSeconds, 90 * 60, accuracy: 0.1)
    }

    func testCalculateCurrentStreakStopsAtMissingDay() throws {
        let now = try makeDate(year: 2026, month: 5, day: 21, hour: 12, minute: 0)
        let today = try makeDate(year: 2026, month: 5, day: 21, hour: 8, minute: 0)
        let yesterday = try makeDate(year: 2026, month: 5, day: 20, hour: 8, minute: 0)
        let threeDaysAgo = try makeDate(year: 2026, month: 5, day: 18, hour: 8, minute: 0)

        let sessions = [
            makeSession(start: today, plannedMinutes: 10, actualMinutes: 10, status: .completed),
            makeSession(start: yesterday, plannedMinutes: 10, actualMinutes: 10, status: .completed),
            makeSession(start: threeDaysAgo, plannedMinutes: 10, actualMinutes: 10, status: .completed)
        ]

        let stats = StatsCalculator.calculate(sessions: sessions, now: now, calendar: calendar)

        XCTAssertEqual(stats.currentStreak, 2)
    }

    func testCalculateTracksExtendedMinutes() throws {
        let now = try makeDate(year: 2026, month: 5, day: 21, hour: 12, minute: 0)
        let start = try makeDate(year: 2026, month: 5, day: 21, hour: 8, minute: 0)

        let session = makeSession(
            start: start,
            plannedMinutes: 60,
            actualMinutes: 75,
            status: .completed,
            extendedMinutes: 15
        )

        let stats = StatsCalculator.calculate(sessions: [session], now: now, calendar: calendar)

        XCTAssertEqual(stats.extendedTimeTotal, 15 * 60, accuracy: 0.1)
        XCTAssertEqual(stats.averageSessionLength, 75 * 60, accuracy: 0.1)
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) throws -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return try XCTUnwrap(components.date)
    }

    private func makeSession(
        start: Date,
        plannedMinutes: Int,
        actualMinutes: Int,
        status: SessionStatus,
        extendedMinutes: Int = 0,
        reason: UnlockReason? = nil
    ) -> DetoxSessionRecord {
        DetoxSessionRecord(
            startDate: start,
            plannedEndDate: start.addingTimeInterval(TimeInterval(plannedMinutes * 60)),
            actualEndDate: start.addingTimeInterval(TimeInterval(actualMinutes * 60)),
            initialDurationMinutes: plannedMinutes - extendedMinutes,
            extendedMinutes: extendedMinutes,
            status: status,
            unlockReason: reason,
            modeId: DetoxMode.defaultModeID,
            modeName: "Default Detox",
            blockedAppCount: 5
        )
    }
}
```

- [ ] **Step 4: Add `DetoxSessionRecordTests.swift`**

Create `ScreenLockerTests/DetoxSessionRecordTests.swift`:

```swift
import XCTest
@testable import ScreenLocker

final class DetoxSessionRecordTests: XCTestCase {
    func testComputedSessionValuesForActiveSession() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let plannedEnd = start.addingTimeInterval(60 * 60)
        let halfWay = start.addingTimeInterval(30 * 60)
        let session = DetoxSessionRecord(
            startDate: start,
            plannedEndDate: plannedEnd,
            initialDurationMinutes: 60,
            status: .active,
            modeId: DetoxMode.defaultModeID,
            modeName: "Default Detox",
            blockedAppCount: 5
        )

        XCTAssertEqual(session.plannedDuration, 60 * 60, accuracy: 0.1)
        XCTAssertEqual(session.remainingTime(at: halfWay), 30 * 60, accuracy: 0.1)
        XCTAssertEqual(session.progress(at: halfWay), 0.5, accuracy: 0.001)
        XCTAssertFalse(session.wasExtended)
        XCTAssertFalse(session.wasBroken)
    }

    func testComputedSessionValuesForBrokenExtendedSession() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let plannedEnd = start.addingTimeInterval(90 * 60)
        let actualEnd = start.addingTimeInterval(25 * 60)
        let session = DetoxSessionRecord(
            startDate: start,
            plannedEndDate: plannedEnd,
            actualEndDate: actualEnd,
            initialDurationMinutes: 60,
            extendedMinutes: 30,
            status: .broken,
            unlockReason: .lockTooLong,
            modeId: DetoxMode.defaultModeID,
            modeName: "Default Detox",
            blockedAppCount: 5
        )

        XCTAssertEqual(session.totalPlannedMinutes, 90)
        XCTAssertEqual(session.actualDuration(), 25 * 60, accuracy: 0.1)
        XCTAssertTrue(session.wasExtended)
        XCTAssertTrue(session.wasBroken)
        XCTAssertEqual(session.unlockReason, .lockTooLong)
    }
}
```

- [ ] **Step 5: Run focused tests**

Run:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:ScreenLockerTests/StatsCalculatorTests \
  -only-testing:ScreenLockerTests/DetoxSessionRecordTests \
  test
```

Expected: all new tests pass.

- [ ] **Step 6: Commit**

```sh
git add ScreenLocker.xcodeproj/project.pbxproj ScreenLockerTests
git commit -m "test: add session statistics coverage"
```

---

### Task 2: Harden Screen Time State Reporting

**Files:**
- Create: `ScreenLocker/Models/BlockingAuthorizationState.swift`
- Create: `ScreenLocker/Models/ShieldingResult.swift`
- Create: `ScreenLocker/Views/ScreenTimeStatusView.swift`
- Modify: `ScreenLocker/Services/AppBlockingManager.swift`
- Modify: `ScreenLocker/Views/BlockedAppsView.swift`
- Modify: `ScreenLocker/Views/TimerView.swift`
- Modify: `ScreenLocker.xcodeproj/project.pbxproj`

- [ ] **Step 1: Move authorization state into its own model file**

Create `ScreenLocker/Models/BlockingAuthorizationState.swift`:

```swift
import Foundation

enum BlockingAuthorizationState: String {
    case notDetermined
    case approved
    case denied
    case unavailable

    var title: String {
        switch self {
        case .notDetermined:
            "Not Requested"
        case .approved:
            "Allowed"
        case .denied:
            "Denied"
        case .unavailable:
            "Unavailable"
        }
    }

    var userMessage: String {
        switch self {
        case .notDetermined:
            "Screen Time access has not been requested yet."
        case .approved:
            "Screen Time access is allowed."
        case .denied:
            "Screen Time access is denied. The timer can still run without app shielding."
        case .unavailable:
            "Screen Time APIs are unavailable in this build or configuration."
        }
    }
}
```

Remove the existing `BlockingAuthorizationState` declaration from `ScreenLocker/Services/AppBlockingManager.swift`.

- [ ] **Step 2: Add shielding result model**

Create `ScreenLocker/Models/ShieldingResult.swift`:

```swift
import Foundation

struct ShieldingResult: Equatable {
    let didApplyShields: Bool
    let selectedItemCount: Int
    let message: String?

    static func applied(selectedItemCount: Int) -> ShieldingResult {
        ShieldingResult(
            didApplyShields: true,
            selectedItemCount: selectedItemCount,
            message: nil
        )
    }

    static func fallback(selectedItemCount: Int, message: String) -> ShieldingResult {
        ShieldingResult(
            didApplyShields: false,
            selectedItemCount: selectedItemCount,
            message: message
        )
    }
}
```

- [ ] **Step 3: Update `AppBlockingManager.applyBlocking`**

Change the signature in `ScreenLocker/Services/AppBlockingManager.swift`:

```swift
@discardableResult
func applyBlocking(from settingsStore: SettingsStore) -> ShieldingResult
```

Use this implementation shape:

```swift
@discardableResult
func applyBlocking(from settingsStore: SettingsStore) -> ShieldingResult {
    #if canImport(FamilyControls) && canImport(ManagedSettings)
    guard authorizationState == .approved else {
        isShieldingActive = false
        let message = "Screen Time access is not approved. The local timer will continue without app shielding."
        lastErrorMessage = message
        return .fallback(selectedItemCount: settingsStore.blockedAppCount, message: message)
    }

    let selection = settingsStore.activitySelection
    let selectedItemCount = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count

    managedSettingsStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
    managedSettingsStore.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
    managedSettingsStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens

    isShieldingActive = selectedItemCount > 0

    if isShieldingActive {
        lastErrorMessage = nil
        return .applied(selectedItemCount: selectedItemCount)
    } else {
        let message = "No Screen Time apps are selected. Mock blocked app count is shown in the UI."
        lastErrorMessage = message
        return .fallback(selectedItemCount: settingsStore.blockedAppCount, message: message)
    }
    #else
    isShieldingActive = false
    let message = "Screen Time shielding is unavailable in this build."
    lastErrorMessage = message
    return .fallback(selectedItemCount: settingsStore.blockedAppCount, message: message)
    #endif
}
```

- [ ] **Step 4: Add reusable status view**

Create `ScreenLocker/Views/ScreenTimeStatusView.swift`:

```swift
import SwiftUI

struct ScreenTimeStatusView: View {
    let authorizationState: BlockingAuthorizationState
    let isShieldingActive: Bool
    let message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .foregroundStyle(tint)

                Text("Screen Time")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                Text(authorizationState.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }

            Text(message ?? authorizationState.userMessage)
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .detoxCard(padding: 14, cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        if isShieldingActive {
            return "shield.checkered"
        }

        switch authorizationState {
        case .approved:
            return "checkmark.shield.fill"
        case .denied, .unavailable:
            return "exclamationmark.triangle.fill"
        case .notDetermined:
            return "shield"
        }
    }

    private var tint: Color {
        if isShieldingActive {
            return AppTheme.cyan
        }

        switch authorizationState {
        case .approved:
            return AppTheme.cyan
        case .denied, .unavailable:
            return AppTheme.warning
        case .notDetermined:
            return AppTheme.secondaryText
        }
    }
}
```

- [ ] **Step 5: Replace duplicated status UI**

In `BlockedAppsView`, replace the custom Screen Time status card with:

```swift
ScreenTimeStatusView(
    authorizationState: appBlockingManager.authorizationState,
    isShieldingActive: appBlockingManager.isShieldingActive,
    message: appBlockingManager.lastErrorMessage
)
```

In `TimerView`, replace the warning-only label with the same view when the state is not approved or when `lastErrorMessage` is non-nil:

```swift
if appBlockingManager.authorizationState != .approved || appBlockingManager.lastErrorMessage != nil {
    ScreenTimeStatusView(
        authorizationState: appBlockingManager.authorizationState,
        isShieldingActive: appBlockingManager.isShieldingActive,
        message: appBlockingManager.lastErrorMessage
    )
}
```

- [ ] **Step 6: Build**

Run:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Expected: build succeeds with 0 errors.

- [ ] **Step 7: Commit**

```sh
git add ScreenLocker.xcodeproj/project.pbxproj ScreenLocker/Models ScreenLocker/Services/AppBlockingManager.swift ScreenLocker/Views
git commit -m "feat: improve screen time status reporting"
```

---

### Task 3: Replace Placeholder Pro Unlock With StoreKit 2 Infrastructure

**Files:**
- Create: `ScreenLocker/Models/ProProduct.swift`
- Modify: `ScreenLocker/Services/PurchaseManager.swift`
- Modify: `ScreenLocker/Views/ProViews.swift`
- Modify: `ScreenLocker.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add product metadata**

Create `ScreenLocker/Models/ProProduct.swift`:

```swift
import Foundation

enum ProProduct {
    static let lifetimeProductID = "com.example.ScreenLocker.pro.lifetime"
    static let allProductIDs: Set<String> = [lifetimeProductID]
}
```

- [ ] **Step 2: Replace `PurchaseManager` implementation**

Replace `ScreenLocker/Services/PurchaseManager.swift` with:

```swift
import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing
        case purchased
        case failed(String)
    }

    @Published private(set) var isProUnlocked: Bool
    @Published private(set) var products: [Product] = []
    @Published private(set) var state: PurchaseState = .idle
    @Published var lastMessage: String?

    private let defaults: UserDefaults
    private let proKey = "isProUnlocked"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isProUnlocked = defaults.bool(forKey: proKey)

        Task {
            await refreshPurchasedProducts()
            await loadProducts()
        }
    }

    func loadProducts() async {
        state = .loading

        do {
            products = try await Product.products(for: Array(ProProduct.allProductIDs))
            state = isProUnlocked ? .purchased : .idle
        } catch {
            state = .failed("Products could not be loaded. Check StoreKit configuration.")
            lastMessage = "Products could not be loaded. Check StoreKit configuration."
        }
    }

    func purchasePro() async {
        if products.isEmpty {
            await loadProducts()
        }

        guard let product = products.first(where: { $0.id == ProProduct.lifetimeProductID }) else {
            unlockProForLocalDemo()
            return
        }

        state = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                unlockPro()
                await transaction.finish()
                lastMessage = "Pro access is active."
                state = .purchased
            case .userCancelled:
                state = .idle
                lastMessage = "Purchase cancelled."
            case .pending:
                state = .idle
                lastMessage = "Purchase is pending approval."
            @unknown default:
                state = .failed("Purchase could not be completed.")
                lastMessage = "Purchase could not be completed."
            }
        } catch {
            state = .failed("Purchase failed. Try again later.")
            lastMessage = "Purchase failed. Try again later."
        }
    }

    func restorePurchases() {
        Task {
            await refreshPurchasedProducts()
            lastMessage = isProUnlocked ? "Pro access is active." : "No active Pro purchase was found."
            state = isProUnlocked ? .purchased : .idle
        }
    }

    func unlockProForLocalDemo() {
        unlockPro()
        lastMessage = "Pro unlocked locally because no StoreKit product is configured."
        state = .purchased
    }

    private func refreshPurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == ProProduct.lifetimeProductID {
                unlockPro()
                state = .purchased
                return
            }
        }
    }

    private func unlockPro() {
        isProUnlocked = true
        defaults.set(true, forKey: proKey)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreKitError.failedVerification
        }
    }
}
```

- [ ] **Step 3: Update Pro button**

In `ProUnlockView`, replace the `PrimaryButton` action with an async StoreKit call:

```swift
PrimaryButton(
    title: purchaseManager.isProUnlocked ? "Pro Active" : "Unlock Pro",
    systemImage: purchaseManager.isProUnlocked ? "checkmark.seal.fill" : "crown.fill",
    isDisabled: purchaseManager.isProUnlocked
) {
    Task {
        await purchaseManager.purchasePro()
    }
}
```

Show the purchase state below the button:

```swift
if let message = purchaseManager.lastMessage {
    Text(message)
        .font(.footnote)
        .foregroundStyle(AppTheme.secondaryText)
        .fixedSize(horizontal: false, vertical: true)
}
```

- [ ] **Step 4: Build**

Run:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Expected: build succeeds. On simulator without StoreKit configuration, tapping Unlock Pro uses local demo unlock and shows the local unlock message.

- [ ] **Step 5: Commit**

```sh
git add ScreenLocker.xcodeproj/project.pbxproj ScreenLocker/Models/ProProduct.swift ScreenLocker/Services/PurchaseManager.swift ScreenLocker/Views/ProViews.swift
git commit -m "feat: add storekit pro foundation"
```

---

### Task 4: Add Persisted Schedule Models And Editor UI

**Files:**
- Create: `ScreenLocker/Models/DetoxScheduleRecord.swift`
- Create: `ScreenLocker/Services/ScheduleManager.swift`
- Create: `ScreenLocker/Views/ScheduleEditorView.swift`
- Modify: `ScreenLocker/ScreenLockerApp.swift`
- Modify: `ScreenLocker/Views/ProViews.swift`
- Modify: `ScreenLocker.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add SwiftData schedule model**

Create `ScreenLocker/Models/DetoxScheduleRecord.swift`:

```swift
import Foundation
import SwiftData

@Model
final class DetoxScheduleRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var weekdayRawValues: [Int]
    var durationMinutes: Int
    var isEnabled: Bool
    var modeId: UUID?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        weekdayRawValues: [Int],
        durationMinutes: Int,
        isEnabled: Bool,
        modeId: UUID? = DetoxMode.defaultModeID,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.weekdayRawValues = weekdayRawValues
        self.durationMinutes = durationMinutes
        self.isEnabled = isEnabled
        self.modeId = modeId
        self.createdAt = createdAt
    }

    var timeRangeText: String {
        "\(Self.format(hour: startHour, minute: startMinute)) - \(Self.format(hour: endHour, minute: endMinute))"
    }

    var weekdayText: String {
        let symbols = Calendar.current.shortWeekdaySymbols
        return weekdayRawValues
            .sorted()
            .compactMap { value in
                guard value >= 1 && value <= symbols.count else { return nil }
                return symbols[value - 1]
            }
            .joined(separator: " ")
    }

    private static func format(hour: Int, minute: Int) -> String {
        let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
```

- [ ] **Step 2: Add schedule model to SwiftData schema**

In `ScreenLocker/ScreenLockerApp.swift`, change:

```swift
let schema = Schema([DetoxSessionRecord.self])
```

to:

```swift
let schema = Schema([DetoxSessionRecord.self, DetoxScheduleRecord.self])
```

- [ ] **Step 3: Add schedule manager**

Create `ScreenLocker/Services/ScheduleManager.swift`:

```swift
import Foundation
import SwiftData

@MainActor
final class ScheduleManager: ObservableObject {
    @Published private(set) var schedules: [DetoxScheduleRecord] = []
    @Published var lastErrorMessage: String?

    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = modelContext
        loadSchedules()
    }

    func loadSchedules() {
        guard let modelContext else { return }

        do {
            let descriptor = FetchDescriptor<DetoxScheduleRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            schedules = try modelContext.fetch(descriptor)
        } catch {
            lastErrorMessage = "Schedules could not be loaded."
        }
    }

    func addDefaultSchedule() {
        guard let modelContext else { return }

        let schedule = DetoxScheduleRecord(
            title: "Focus Time",
            startHour: 9,
            startMinute: 0,
            endHour: 12,
            endMinute: 0,
            weekdayRawValues: [2, 3, 4, 5, 6],
            durationMinutes: 180,
            isEnabled: true
        )

        modelContext.insert(schedule)
        schedules.append(schedule)
        save()
    }

    func toggle(_ schedule: DetoxScheduleRecord, isEnabled: Bool) {
        schedule.isEnabled = isEnabled
        save()
        loadSchedules()
    }

    func delete(_ schedule: DetoxScheduleRecord) {
        modelContext?.delete(schedule)
        schedules.removeAll { $0.id == schedule.id }
        save()
    }

    private func save() {
        do {
            try modelContext?.save()
        } catch {
            lastErrorMessage = "Schedule changes could not be saved."
        }
    }
}
```

- [ ] **Step 4: Add manager to app environment**

In `ScreenLocker/ScreenLockerApp.swift`, add:

```swift
@StateObject private var scheduleManager = ScheduleManager()
```

and pass it into the environment:

```swift
.environmentObject(scheduleManager)
```

In `RootTabView`, configure it beside `DetoxSessionViewModel`:

```swift
@EnvironmentObject private var scheduleManager: ScheduleManager
```

Inside `.task`:

```swift
scheduleManager.configure(modelContext: modelContext)
```

- [ ] **Step 5: Create schedule editor**

Create `ScreenLocker/Views/ScheduleEditorView.swift`:

```swift
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
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
        scheduleManager.addDefaultSchedule()
    }
}
```

After this compiles, improve `ScheduleManager` with an `addSchedule(...)` method and update `ScheduleEditorView.save()` to pass selected values. Keep the first compile step small.

- [ ] **Step 6: Replace preview schedule list with persisted schedules**

In `SchedulesView`, inject:

```swift
@EnvironmentObject private var scheduleManager: ScheduleManager
@State private var showingScheduleEditor = false
```

Use `scheduleManager.schedules` for the list. If empty, show a card:

```swift
Text("No schedules yet")
    .font(.headline.weight(.semibold))
    .foregroundStyle(AppTheme.primaryText)

Text("Create a Pro schedule to prepare recurring detox windows.")
    .font(.subheadline)
    .foregroundStyle(AppTheme.secondaryText)
```

Wire the toolbar plus button:

```swift
Button {
    showingScheduleEditor = true
} label: {
    Image(systemName: "plus")
}
.disabled(!purchaseManager.isProUnlocked)
.sheet(isPresented: $showingScheduleEditor) {
    ScheduleEditorView()
}
```

- [ ] **Step 7: Build**

Run:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Expected: build succeeds and Settings -> Schedules opens with either an empty state or persisted schedules.

- [ ] **Step 8: Commit**

```sh
git add ScreenLocker.xcodeproj/project.pbxproj ScreenLocker/Models/DetoxScheduleRecord.swift ScreenLocker/Services/ScheduleManager.swift ScreenLocker/Views/ScheduleEditorView.swift ScreenLocker/ScreenLockerApp.swift ScreenLocker/Views/ProViews.swift
git commit -m "feat: add persisted schedule foundation"
```

---

### Task 5: Add Guarded DeviceActivity Schedule Adapter

**Files:**
- Create: `ScreenLocker/Services/DeviceActivityScheduleAdapter.swift`
- Modify: `ScreenLocker/Services/ScheduleManager.swift`
- Modify: `docs/screen_time_setup_notes.md`
- Modify: `ScreenLocker.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add guarded adapter**

Create `ScreenLocker/Services/DeviceActivityScheduleAdapter.swift`:

```swift
import Foundation

#if canImport(DeviceActivity)
import DeviceActivity
#endif

@MainActor
final class DeviceActivityScheduleAdapter {
    enum AdapterResult: Equatable {
        case scheduled
        case cleared
        case unavailable(String)
        case failed(String)
    }

    func apply(_ schedule: DetoxScheduleRecord) -> AdapterResult {
        #if canImport(DeviceActivity)
        guard schedule.isEnabled else {
            return clear(schedule)
        }

        let intervalStart = DateComponents(hour: schedule.startHour, minute: schedule.startMinute)
        let intervalEnd = DateComponents(hour: schedule.endHour, minute: schedule.endMinute)
        let deviceSchedule = DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            repeats: true
        )

        do {
            try DeviceActivityCenter().startMonitoring(
                DeviceActivityName(schedule.id.uuidString),
                during: deviceSchedule
            )
            return .scheduled
        } catch {
            return .failed("DeviceActivity monitoring could not be started.")
        }
        #else
        return .unavailable("DeviceActivity is unavailable in this build.")
        #endif
    }

    func clear(_ schedule: DetoxScheduleRecord) -> AdapterResult {
        #if canImport(DeviceActivity)
        DeviceActivityCenter().stopMonitoring([DeviceActivityName(schedule.id.uuidString)])
        return .cleared
        #else
        return .unavailable("DeviceActivity is unavailable in this build.")
        #endif
    }
}
```

- [ ] **Step 2: Connect adapter from `ScheduleManager`**

In `ScheduleManager`, add:

```swift
private let deviceActivityAdapter = DeviceActivityScheduleAdapter()
```

In `toggle(_:isEnabled:)`, after saving:

```swift
let result = isEnabled ? deviceActivityAdapter.apply(schedule) : deviceActivityAdapter.clear(schedule)
if case .failed(let message) = result {
    lastErrorMessage = message
}
if case .unavailable(let message) = result {
    lastErrorMessage = message
}
```

- [ ] **Step 3: Document DeviceActivity requirements**

Append this section to `docs/screen_time_setup_notes.md`:

```markdown
## DeviceActivity Scheduling Notes

The schedule foundation uses `DeviceActivityScheduleAdapter` to keep DeviceActivity calls isolated from SwiftUI screens.

Manual setup required before real scheduled monitoring is expected:

1. Confirm DeviceActivity capability and related entitlements in the Apple Developer account.
2. Add any required DeviceActivity monitor extension target if schedule callbacks need to trigger shielding outside the foreground app.
3. Test on a physical device with Screen Time authorization approved.
4. Confirm schedules are cleared when users disable a schedule or delete it.

The app must continue to show a clear unavailable/fallback message when DeviceActivity cannot start monitoring.
```

- [ ] **Step 4: Build**

Run:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Expected: build succeeds. Simulator may report unavailable DeviceActivity behavior through `lastErrorMessage`.

- [ ] **Step 5: Commit**

```sh
git add ScreenLocker.xcodeproj/project.pbxproj ScreenLocker/Services/DeviceActivityScheduleAdapter.swift ScreenLocker/Services/ScheduleManager.swift docs/screen_time_setup_notes.md
git commit -m "feat: add device activity schedule adapter"
```

---

### Task 6: Generate App Icon Artwork With Image Gen

**Files:**
- Create: `tmp/imagegen/screen-locker-app-icon-source.png`
- Create: `ScreenLocker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
- Modify: `ScreenLocker/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] **Step 1: Open the image generation skill**

Read the project-local skill instructions before generating the icon:

```sh
sed -n '1,220p' /Users/nf/.codex/skills/.system/imagegen/SKILL.md
```

Use the built-in `image_gen` tool by default. Do not use a CLI fallback unless the user explicitly requests it.

- [ ] **Step 2: Generate the app icon candidate**

Use this prompt with the `imagegen` skill:

```text
Use case: logo-brand
Asset type: iOS app icon, square raster artwork for a digital detox timer app
Primary request: Create a premium dark minimal iOS app icon for an app named Detox that helps users protect focus time by blocking distracting apps.
Style: chic, modern, calm, high contrast, native iOS quality, not cartoonish.
Subject: an abstract shield combined with a subtle timer/progress ring motif.
Palette: near-black background, deep charcoal depth, violet-blue-cyan luminous accent, tiny warm gold highlight allowed.
Composition: centered symbol, generous safe padding, readable at small sizes, no text, no letters, no numbers.
Rendering: polished 3D-soft-gradient icon, smooth bevels, subtle glow, crisp edges, no mockup device, no watermark.
Output: square app icon artwork suitable for 1024 by 1024 iOS asset catalog use.
```

Save the selected generated file into the workspace as:

```text
tmp/imagegen/screen-locker-app-icon-source.png
```

- [ ] **Step 3: Create the asset catalog image**

Create a 1024 x 1024 PNG from the selected source:

```sh
sips -z 1024 1024 tmp/imagegen/screen-locker-app-icon-source.png --out ScreenLocker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
```

Expected: `ScreenLocker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` exists and is 1024 x 1024.

- [ ] **Step 4: Update app icon contents**

Replace `ScreenLocker/Assets.xcassets/AppIcon.appiconset/Contents.json` with:

```json
{
  "images" : [
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 5: Verify the icon asset**

Run:

```sh
file ScreenLocker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
sips -g pixelWidth -g pixelHeight ScreenLocker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
```

Expected:

```text
pixelWidth: 1024
pixelHeight: 1024
```

- [ ] **Step 6: Build**

Run:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Expected: build succeeds and asset catalog compilation does not report app icon errors.

- [ ] **Step 7: Commit**

```sh
git add ScreenLocker/Assets.xcassets/AppIcon.appiconset tmp/imagegen/screen-locker-app-icon-source.png
git commit -m "design: add generated app icon"
```

---

### Task 7: Final Verification And Documentation

**Files:**
- Modify: `docs/codex_handoff.md`
- Modify: `docs/screen_time_setup_notes.md`
- Modify: `AGENTS.md` only if project commands or required references changed.

- [ ] **Step 1: Run full build**

Run:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Expected: build succeeds with 0 errors.

- [ ] **Step 2: Run test suite**

Run:

```sh
xcodebuild \
  -project ScreenLocker.xcodeproj \
  -scheme ScreenLocker \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Expected: all XCTest tests pass.

- [ ] **Step 3: Manual smoke test**

On iPhone 17 simulator, verify:

- App launches to Timer.
- Timer can start without Screen Time authorization.
- Active lock screen appears.
- Extend `+5 min` updates remaining time.
- Unlock long press opens Unlock Request.
- Unlock waits for the configured countdown and records a broken session.
- Insights reflects the broken session and extended minutes.
- Settings -> Blocked Apps shows Screen Time status.
- Settings -> Go Pro can unlock locally if StoreKit products are unavailable.
- Settings -> Schedules opens and preserves schedule entries across app relaunch.
- Settings -> Deep Lock keeps the wording "reducing common escape routes".
- App icon appears on the simulator Home Screen after install.

- [ ] **Step 4: Update handoff doc**

Update `docs/codex_handoff.md` sections:

- `Current Status`
- `Last verified`
- `Known Limitations`
- `Good Next Tasks`

Record the exact build/test commands and outcomes.

- [ ] **Step 5: Commit docs**

```sh
git add docs/codex_handoff.md docs/screen_time_setup_notes.md AGENTS.md
git commit -m "docs: update implementation handoff"
```

---

## Self-Review

Spec coverage:

- Tests: covered by Task 1.
- Screen Time hardening: covered by Task 2.
- StoreKit foundation: covered by Task 3.
- Schedules and DeviceActivity foundation: covered by Tasks 4 and 5.
- App icon artwork: covered by Task 6 using the `imagegen` skill.
- Documentation and verification: covered by Task 7.

Known gaps intentionally outside this plan:

- Widgets.
- Live Activity.
- Reflection log.
- Export stats.
- Custom themes.
- Final production App Store product IDs and entitlement provisioning.

Type consistency:

- `DetoxSessionRecord`, `SettingsStore`, `AppBlockingManager`, `PurchaseManager`, and `StatsCalculator` names match the current codebase.
- New model/service names are unique and follow existing naming style.
- `DetoxScheduleRecord` is added to the SwiftData schema before it is used by `ScheduleManager`.

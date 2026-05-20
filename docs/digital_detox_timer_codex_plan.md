# iOS Digital Detox Timer App Implementation Plan for Codex

## 0. Purpose

Build a minimal, stylish, dark-mode iOS app for digital detox.

The app helps users stay away from distracting apps by starting a detox timer, blocking selected apps during the session, showing a large lock screen timer with a progress ring, and visualizing protected time through statistics.

Use the attached UI reference image as the main visual direction.

UI language: English  
Design style: minimal, dark, chic, modern  
Primary target: iPhone  
Initial monetization: Free + one-time Pro unlock

---

## 1. Product Concept

### App concept

A minimal digital detox timer that helps users stay away from distracting apps and visualize their protected time.

### Core user value

The user can clearly see how much time they protected from phone usage.

The main emotional payoff is:

> "I stayed away from my phone for this long."

---

## 2. UI Reference

Use the provided UI mockup image as the visual reference.

Expected screens in the reference:

1. Home / Timer
2. Active Lock Screen
3. Extend Time
4. Unlock Flow
5. Insights Overview
6. Weekly Insights
7. Mode Management
8. Schedule
9. Deep Lock
10. Settings

Important visual characteristics:

- Dark background
- Minimal cards
- Rounded corners
- Subtle gradients
- Purple / blue / cyan accent colors
- Large timer typography
- Progress ring as the visual centerpiece
- Clean bottom tab navigation
- English UI text

Do not copy the image pixel-perfectly. Implement a native SwiftUI version that follows the same product direction.

---

## 3. Technical Assumptions

### Platform

- iOS app
- SwiftUI
- iOS 17+ preferred
- Use native Apple frameworks where possible

### Screen Time related frameworks

Use the following frameworks where appropriate:

- FamilyControls
- ManagedSettings
- DeviceActivity

### Important implementation note

The app should support app blocking using Apple's Screen Time API family.

However, do not claim absolute device lockdown or guaranteed uninstall prevention in the implementation text. Deep Lock should be implemented as a guided setup that reduces common escape routes via iOS Screen Time restrictions.

---

## 4. MVP Scope

The MVP should include:

1. Timer tab
2. App selection / blocked app list
3. Start detox session
4. Active lock screen
5. Extend timer
6. Unlock request flow
7. Basic statistics
8. Settings
9. Free + Pro placeholder structure

Do not implement all Pro functionality at once. Add screens and state models so Pro features can be enabled later.

---

## 5. Navigation Structure

Use a bottom tab layout.

Tabs:

1. Timer
2. Insights
3. Settings

### Timer tab

Main entry point for starting a detox session.

### Insights tab

Displays protected time and session statistics.

### Settings tab

Displays blocked apps, default duration, unlock delay, notifications, appearance, stats/data, restore purchase, and Pro-related entries.

---

## 6. Main Data Model

Create models similar to the following.

### DetoxSession

Fields:

- id: UUID
- startDate: Date
- plannedEndDate: Date
- actualEndDate: Date?
- initialDurationMinutes: Int
- extendedMinutes: Int
- status: completed | broken | active
- unlockReason: UnlockReason?
- modeId: UUID?
- blockedAppCount: Int

Computed values:

- plannedDuration
- actualDuration
- progress
- remainingTime
- wasExtended
- wasBroken

### DetoxStats

Fields:

- protectedTimeToday
- protectedTimeAllTime
- sessionCountToday
- averageSessionLength
- completionRate
- currentStreak
- weeklyProtectedTime
- extendedTimeTotal
- brokenSessionCount

### DetoxMode

For MVP, one default mode is enough.

Fields:

- id: UUID
- name: String
- iconName: String
- blockedAppCount: Int
- isPro: Bool

Initial mode:

- name: "Default Detox"
- iconName: "shield.fill"

Future Pro modes:

- Sleep Detox
- Deep Focus
- Evening Detox
- Weekend Detox

### UnlockReason

Cases:

- urgentReply
- specificApp
- changedMind
- lockTooLong
- other

Display text:

- "I need to reply urgently"
- "I need a specific app"
- "I changed my mind"
- "The lock was too long"
- "Other"

---

## 7. Screen Requirements

## 7.1 Timer Screen

Purpose:

Start a detox session quickly.

Layout:

- Title: "Timer"
- Pro crown icon at top-right
- Protected today summary
- Daily goal progress
- Default Detox card
- Duration card
- Start Detox button
- Bottom tab navigation

Example UI text:

- "Protected today"
- "2h 40m"
- "Daily goal 4h"
- "Default Detox"
- "5 apps blocked"
- "Duration"
- "60 min"
- "Start Detox"

Interactions:

- Tapping blocked apps opens app selection or settings
- Tapping duration opens duration picker
- Tapping Start Detox starts a session
- If Screen Time permission is missing, show onboarding/permission request first

Acceptance criteria:

- User can select or view blocked apps
- User can set duration
- User can start a detox session
- Starting a session navigates to the active lock screen

---

## 7.2 Active Lock Screen

Purpose:

This is the core experience.

Layout:

- Large digital clock at top
- Large circular progress ring in the center
- Remaining time inside the ring
- Completion percentage below remaining time
- Mode label
- Extend button
- Today protected time
- Small unlock button at bottom

Example UI text:

- "9:41 PM"
- "38:24"
- "remaining"
- "64% complete"
- "Deep Detox"
- "Extend"
- "Today protected: 2h 40m"
- "Unlock"
- "Hold for 2s"

Progress ring:

- Represents elapsed percentage of the current planned session
- Ring should be visually prominent
- Use subtle purple-to-cyan gradient if feasible

Interactions:

- Extend opens Extend Time sheet
- Unlock requires a long press or deliberate tap flow
- Timer updates every second
- When timer completes, session status becomes completed

Acceptance criteria:

- Current time is displayed digitally
- Remaining time is displayed prominently
- Progress ring updates as time passes
- Extend flow works
- Unlock flow is not too prominent
- Completed session is recorded correctly

---

## 7.3 Extend Time Screen

Purpose:

Allow users to extend the detox session.

Layout:

- Title: "Extend"
- Subtitle: "Add more time to your session."
- Options:
  - "+5 min"
  - "+15 min"
  - "+30 min"
  - "Custom..."
- Summary card:
  - "Total session"
  - "60 min → 80 min"
  - "New remaining time"
  - "58:24"

Custom extension:

- Let user input minutes
- Confirm button

Rules:

- Extension count is unlimited
- Every extension is recorded in the session
- Extended time is included in statistics

Acceptance criteria:

- User can extend by preset amounts
- User can input custom extension minutes
- Remaining time and planned end date update correctly
- Extended minutes are saved

---

## 7.4 Unlock Flow

Purpose:

Allow early unlock, but make it intentional.

Flow:

1. User requests unlock
2. Show 30-second waiting countdown
3. Ask reason
4. End session early
5. Record session as broken

Layout:

- Title: "Unlock Request"
- Circular countdown: "30 seconds"
- Text: "Please wait..."
- Question: "Why do you want to stop?"
- Reasons:
  - "I need to reply urgently"
  - "I need a specific app"
  - "I changed my mind"
  - "The lock was too long"
  - "Other"
- Warning card:
  - "This session will be recorded as an early end."

Rules:

- Default unlock delay: 30 seconds
- Early unlock records broken session
- User reason is stored
- Completion rate should reflect broken sessions

Acceptance criteria:

- Unlock request starts a 30-second countdown
- User can select a reason
- Session becomes broken after confirmation
- Statistics update correctly

---

## 7.5 Insights Overview

Purpose:

Show user progress and reinforce value.

Free metrics:

- Protected Time Today
- Sessions Today
- Average Session
- Completion Rate
- Current Streak
- Total Protected

Example UI text:

- "Insights"
- "Today"
- "Week"
- "Month"
- "Year"
- "Protected Time"
- "Sessions"
- "Avg. Session"
- "Completion Rate"
- "Streak"
- "Total Protected"
- "Go Pro"
- "Unlock advanced insights, multiple modes and Deep Lock."

Acceptance criteria:

- Today statistics are calculated from sessions
- All-time protected time is shown
- Completion rate is calculated
- Streak is shown
- Pro upsell card is displayed

---

## 7.6 Weekly Insights

Purpose:

Pro-style advanced statistics screen.

MVP can implement this as a placeholder or partially functional screen.

Layout:

- Weekly bar chart
- This week total
- Comparison vs last week
- Best day
- Best time
- Most improved

Example UI text:

- "Weekly Trend"
- "18h 45m"
- "This week"
- "+18% vs last week"
- "Best day"
- "Best time"
- "Most improved"

Acceptance criteria:

- If Pro is not implemented, show as locked or preview
- If implemented, aggregate sessions by weekday

---

## 7.7 Mode Management

Purpose:

Pro feature for saving different blocked app sets.

For MVP:

- Show Default Detox
- Show locked Pro modes

Example modes:

- Default Detox
- Sleep Detox
- Deep Focus
- Evening Detox
- Weekend Detox

Acceptance criteria:

- MVP supports Default Detox
- Pro modes appear as locked placeholders
- Architecture supports multiple modes later

---

## 7.8 Schedule Screen

Purpose:

Pro feature for scheduled detox sessions.

Examples:

- Weekdays: 10:00 PM – 7:00 AM
- Focus Time: 9:00 AM – 12:00 PM
- Evening Detox: 8:00 PM – 11:00 PM

For MVP:

- Can be a locked Pro preview
- Do not overbuild scheduling in first pass

Acceptance criteria:

- Screen exists or Settings link exists
- Pro upsell is shown
- Architecture allows future schedule implementation

---

## 7.9 Deep Lock Screen

Purpose:

Pro feature and key marketing feature.

Important wording:

Do not promise absolute uninstall prevention.

Use this message:

"Deep Lock helps you stay committed by reducing common escape routes."

Features displayed:

- "Block uninstall & disabling"
  - "Guide to set up via Screen Time"
- "Block system settings access"
  - "Prevent changes during sessions"
- "Require passcode to exit"
  - "Add extra layer of protection"

Primary button:

- "Set Up Deep Lock"

Implementation guidance:

- Deep Lock should be implemented as a guided setup flow initially
- Explain iOS limitations clearly
- Avoid claiming that uninstall prevention is guaranteed solely by this app

Acceptance criteria:

- Deep Lock screen explains the value clearly
- It does not make technically false claims
- It can link to setup instructions or future implementation

---

## 7.10 Settings Screen

Sections:

### General

- Blocked Apps
- Default Duration
- Unlock Delay
- Notifications
- Appearance

### Advanced

- Stats & Data
- Restore Purchase

### Pro

- Modes
- Schedules
- Deep Lock
- Advanced Insights

Acceptance criteria:

- User can change default duration
- User can see unlock delay set to 30 sec
- User can access blocked apps setup
- Restore Purchase entry exists
- Pro entries are visible

---

## 8. Screen Time API Implementation Plan

### Step 1: Permission

Request Family Controls authorization before app selection/blocking.

Required UX:

- Explain why permission is needed
- Request authorization
- Handle denied state gracefully

### Step 2: App selection

Use FamilyActivityPicker for selecting apps/categories/domains.

Store selection locally.

### Step 3: Apply shielding

Use ManagedSettingsStore to shield selected apps during active session.

When session starts:

- Apply shields for selected apps

When session completes or breaks:

- Clear shields

### Step 4: Device activity monitoring

Use DeviceActivity where needed for scheduled/pro features.

For MVP, manual session start/end with ManagedSettings may be enough.

### Step 5: Deep Lock

Treat as later-stage feature.

Start with guided setup and educational UI.

---

## 9. Data Persistence

Use SwiftData or Core Data.

Recommended for MVP:

- SwiftData if project target supports iOS 17+
- Otherwise Core Data

Persist:

- DetoxSession records
- Default duration
- Unlock delay
- App selection
- Pro status placeholder
- Settings

---

## 10. Monetization

Model:

Free + one-time Pro unlock.

Free includes:

- 1 blocked app list
- Basic detox timer
- App blocking
- Timer extension
- Emergency unlock
- Basic stats
- Today / total protected time

Pro includes:

- Unlimited modes
- Advanced insights
- Schedules
- Deep Lock
- Custom themes
- Widgets
- Live Activity
- Reflection log
- Export stats

MVP requirement:

- Add StoreKit-ready structure
- Pro screen and locked states
- Actual in-app purchase can be implemented after core timer flow works

---

## 11. UI Implementation Details

Use SwiftUI.

Suggested design tokens:

- Background: near black
- Card background: dark gray with subtle opacity
- Primary accent: purple-blue gradient
- Secondary accent: cyan
- Text primary: white
- Text secondary: gray
- Corner radius: 20-28
- Large timer font: rounded or monospaced digit style
- Use SF Symbols for icons

Components to create:

- ProgressRingView
- StatCardView
- SettingRowView
- PrimaryButton
- DetoxModeCard
- WeeklyBarChartView
- UnlockReasonRow
- LockScreenTimerView
- ExtendTimeSheet

---

## 12. State Management

Create a central view model.

Suggested:

- DetoxSessionViewModel
- AppBlockingManager
- StatsCalculator
- PurchaseManager placeholder
- SettingsStore

Session states:

- idle
- active
- extending
- unlockRequested
- completed
- broken

---

## 13. Implementation Phases

## Phase 1: UI Shell

Build SwiftUI screens without Screen Time integration.

Deliver:

- Timer screen
- Active lock screen
- Extend sheet
- Unlock flow
- Insights screen
- Settings screen
- Mock data

## Phase 2: Session Logic

Implement real timer behavior.

Deliver:

- Start session
- Countdown
- Progress calculation
- Extend session
- Complete session
- Broken session
- Basic persistence

## Phase 3: Stats

Implement statistics from stored sessions.

Deliver:

- Protected today
- All-time protected
- Sessions count
- Average session
- Completion rate
- Streak
- Weekly aggregation

## Phase 4: Screen Time Integration

Implement app blocking.

Deliver:

- Authorization request
- FamilyActivityPicker
- Store selection
- Apply shields during session
- Clear shields after session

## Phase 5: Pro Structure

Implement locked Pro sections.

Deliver:

- Pro upsell
- Locked modes
- Locked schedules
- Locked deep lock
- Restore purchase placeholder
- StoreKit structure placeholder

## Phase 6: Polish

Deliver:

- Animations
- Haptics
- Accessibility labels
- Empty states
- Error states
- App icon placeholder
- App Store screenshot readiness

---

## 14. Acceptance Criteria

The implementation is acceptable when:

1. App launches successfully
2. UI matches the dark minimal direction of the reference image
3. Timer tab can start a detox session
4. Active lock screen shows:
   - current digital time
   - progress ring
   - remaining time
   - completion percentage
   - extend button
5. User can extend by preset or custom minutes
6. User can request unlock
7. Unlock request waits 30 seconds
8. User selects unlock reason
9. Broken session is recorded
10. Completed session is recorded
11. Insights screen reflects session data
12. Settings screen exposes key settings
13. App selection flow is prepared or implemented
14. ManagedSettings shields selected apps during active session, if entitlements are available
15. Pro-related screens are clearly locked or previewed
16. No misleading claim is made about guaranteed uninstall prevention

---

## 15. Non-goals for First Implementation

Do not implement in the first pass unless core flow is complete:

- Apple Watch app
- Widgets
- Live Activities
- Full StoreKit production purchase flow
- Full scheduling automation
- Complex Deep Lock enforcement
- Export data
- Cloud sync
- Multi-device sync
- Localization beyond English

---

## 16. Suggested First Codex Task

Implement Phase 1 and Phase 2 first.

Task:

Build the SwiftUI UI shell and local session timer logic for the digital detox timer app using the attached UI reference image.

Focus on:

- Timer tab
- Active lock screen
- Extend time sheet
- Unlock flow
- Basic insights
- Settings screen
- Local mock persistence or in-memory model

Do not implement StoreKit or full Screen Time integration in the first task. Add TODO markers and abstraction layers for those.

---

## 17. Notes for Codex

- Prefer small, reviewable changes.
- Keep business logic separate from views.
- Use native SwiftUI components.
- Use mock data first where system entitlements are required.
- Add comments only where they clarify non-obvious behavior.
- Avoid overengineering.
- Preserve a premium, minimal, dark UI.

# Architecture

## Timer state model

`TimerEngine` is a pure state machine with phases:

- `idle` — no session; primary control is Start
- `running` — session open; Lap and Stop
- `paused` — session open; elapsed frozen; Start resumes
- `stopped` — session finished; last elapsed remains visible until a new start

Transitions are explicit. Start while running is an error. Pause/resume are not overloaded onto unrelated states.

## Timestamp calculation

`TimerSnapshot` stores:

- `accumulatedActiveDuration` for completed running segments
- `currentSegmentStartedAt` while running

Elapsed time at instant `t` is:

```
accumulated + (running ? t - currentSegmentStartedAt : 0)
```

The UI refreshes while visible. Truth does not depend on tick count. Backgrounding, locking, and process restoration keep elapsed correct as long as the session timestamps were persisted.

## Persistence

SwiftData models:

- `Space` — id, name, tint, order, createdAt, distraction timeout, optional Focus keyword
- `TaskItem` — id, parent Space, name, order, enabled, createdAt
- `Session` — id, Space, start, optional end, phase, accumulated duration, active task
- `TaskInterval` — id, Session, Task, start, optional end

No cloud. Tests use an in-memory `ModelContainer`.

## Task interval bookkeeping

Start opens a `TaskInterval` for the first enabled task. Lap ends the open interval and immediately opens the next enabled task, wrapping to the first. Manual selection ends the open interval and opens the chosen task. Stop ends the open interval and the session. There is never more than one open interval.

## Space paging and gesture isolation

A `TabView` with page style lives only in the upper stopwatch region. The lower task panel is a sibling, not a child of the pager, so a horizontal drag that begins on the task list cannot change Space. XCUITest swipes each region by coordinate and asserts Space identity.

## Live Activity boundary

`SessionActivityAttributes` is compiled into the app and the widget extension. The app starts/updates/ends the activity through ActivityKit. The widget renders Lock Screen and Dynamic Island UI. Count-up uses `Text(timerInterval:countsDown: false)` while running so the system can animate time without a one-hertz wake. Interactive controls are App Intents with `openAppWhenRun = true` to avoid App Group entitlements.

## App Intent boundary

Intents call `AppRuntime.shared.sessionController`. Suggested App Shortcuts cover start, stop, next task, and JSON import. Import validates a strict `{name, color, tasks}` schema. Focus is implemented as `SetFocusFilterIntent` (select Space when a user-configured Focus activates). The app does not set system Focus.

## Notification workaround

`Distraction Started` schedules a local notification only if a session is running. `Distraction Ended` cancels that identifier. Default threshold is 5 minutes. This is not Screen Time.

## Test architecture

- Pure tests: `TimerEngine`, `ElapsedFormatter`, `SpaceImportPayload`, `DistractionMonitor`
- SwiftData tests: `SessionController` with in-memory store and `ControllableTimeSource`
- UI tests: launch arguments `-UITests`, `-ResetStore`, `-ScreenshotMode`, `-PersistStore`

## CI architecture

Linux agent never runs Xcode. `.github/workflows/ios-ci.yml` on `macos-26`:

1. Print macOS / Xcode / Swift / simulator summary
2. Install pinned XcodeGen
3. Generate the project
4. Simulator build
5. Unit + UI tests
6. Unsigned `generic/platform=iOS` Release build
7. Zip `Payload/ProductivityTracker.app` as `ProductivityTracker-unsigned.ipa`
8. Upload artifact `ProductivityTracker-iOS-device-unsigned`

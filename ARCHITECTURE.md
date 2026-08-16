# Architecture

## Timer state model

Each Space owns a `TimerEngine` / `TimerSnapshot`. At most one Space is `running`.

User-visible phases match Apple Clock:

- `idle` — `00:00.00`; Lap disabled; Start
- `running` — advancing; Lap; Stop
- `stopped` — frozen and resumable; Reset; Start

`Stop` freezes elapsed, closes the open task interval, and leaves `Session.endedAt` nil. `Start` from stopped resumes the same session. `Reset` archives one historical session (`endedAt` set), dismisses the Live Activity immediately, and returns the display to idle.

Persisted `"paused"` maps to `stopped`.

## Timestamp calculation

`TimerSnapshot` stores `accumulatedBeforeCurrentRun` plus `startedAt` while running.

```
idle: 0
stopped: accumulatedBeforeCurrentRun
running: accumulated + (now - startedAt)
```

Truth never depends on frame count.

## Persistence

SwiftData models:

- `Space` — name, accent, order, reminder seconds (`0` = Off), Focus keyword, default task, icon (SF Symbol, emoji, or monogram)
- `TaskItem` — name, order, enabled, completed
- `Session` — space, start, optional `endedAt` (nil = current/resumable), phase, accumulated, active task
- `TaskInterval` — session, task, start, optional end

Open sessions restore per Space. If more than one was stored as running, extras are frozen.

## Task intervals

Start opens an interval for the selected / default / first enabled task. Direct task tap while running closes the previous interval and opens the new one at the same timestamp. Same-task tap is a no-op. Lap advances to the next enabled task. Deleting the active task moves to the next enabled task or continues with no task.

Task-row totals are the current stopwatch session only. They clear on Reset. History keeps archived totals.

## Task list interaction

Each Space page includes its task list on the same full-page canvas (not a separate lower card region).

- Single tap selects the task for timing while running.
- Double-tap toggles complete / incomplete.
- Context menu: Complete / Mark Incomplete, Rename, Enable / Disable, Delete.
- Inline **Add a task** field at the bottom of the list.

## Space paging

A page-style `TabView` fills the screen. Each page is one Space: header (icon + name), stopwatch, Lap/Start/Stop/Reset controls, page dots, and tasks together. Swiping a Space does not move elapsed time onto the newly visible Space. Starting Space B while A is running freezes A, then starts or resumes B.

A trailing **New Space** page (Apple Home Screen–style extra page) lets you compose a Space before it exists: name, initial tasks, accent color, and icon (SF Symbols, emoji, or monogram from the name). Creating it selects that Space and returns to its page.

Space tint is a top-to-bottom color wash on black, not giant tinted glass cards.

## Live Activity

`SessionActivityAttributes.ContentState` carries space name, current task, running flag, elapsed, tint, and workspace icon.

Lock Screen layout:

- Large space-colored **space name**
- Current task subtitle
- Elapsed via `Text(timerInterval:countsDown:false, showsHours:true)` while running. Stopped uses the same formatter with `pauseTime`. Resume **replaces** that view (new `displayStart` / `elapsedClockID`) instead of clearing `pauseTime` on the paused instance — the system timer does not unfreeze otherwise.
- Explicit **Stop** (`StopFromLiveActivityIntent`) or **Start** (`ResumeFromLiveActivityIntent`) plus **Reset** (`xmark`). Not a `Toggle` / `SetValueIntent` (that control can pause twice and never resume).
- Large workspace icon on the trailing edge
- Background tint from the Space color (`activityBackgroundTint`)

Default activity taps do not mutate the timer (`LiveActivityPresentation.backgroundMutatesTimer == false`). Stop updates the activity as frozen. Reset dismisses with `.immediate`.

## App Intents

Intents call `AppRuntime.shared.sessionController`. Pause intents freeze like Stop. Resume intents call Start. Focus Filter selects a Space. No backend.

## Notifications

`Distraction Started` schedules a local reminder only if a timer is running and the Space reminder is not Off. Copy is `Work · 42:18` / `Timer is still running.` Actions: Continue, Stop.

## Test architecture

- Engine and formatter unit tests
- Stopwatch semantics (stop / resume / reset)
- Task interval and editing tests
- Per-Space ownership tests
- Live Activity state tests
- UI tests: full-page paging isolation, labels, long-press Lap, compose page, screenshots, Live Activity preview canvas

## CI architecture

Linux agent never runs Xcode. `.github/workflows/ios-ci.yml` on `macos-26` generates the Xcode project, tests, packages `conduit-unsigned.ipa` (`Payload/ProductivityTracker.app` inside), and uploads `conduit-iOS-device-unsigned`.

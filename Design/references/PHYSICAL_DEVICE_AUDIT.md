# Physical-device observations

Attachments were inspected from the task (main screen, Live Activity, original concept). Bytes were not always available to commit; this file records the audit.

## Main screen (installed build — pre-fix)

- Two large tinted rounded rectangles on black (upper timer, lower tasks).
- Space color fills those surfaces (brown/teal), not a small accent.
- Timer `00:31`-class digits sit inside a card, not on the canvas like Clock.
- Controls sit inside the same tinted card; glass wrapping is visible.
- Task rows live in a second card rather than a list on the same black field.
- Interaction felt unsmooth: hundredths stepped; paging felt like sliding cards.

## Live Activity (installed build — pre-fix)

- Pause + `xmark` clustered on the leading edge; timer secondary.
- `xmark` reads as dismiss, not Stop.
- Layout felt like a custom mini-app inside the system activity, not a status surface.
- Stop appeared to tear down the activity instead of freezing a resumable stopwatch.

## Causes in code (pre-fix)

- `GlassSurface` applied Space tint glass to both main regions.
- `GlassEffectContainer` around Lap/Start.
- `SessionController.stop()` set `endedAt` and called `liveActivity.end(... .after(.now + 8))`.
- Stopped Start called `resetStoppedDisplay()` then `start()` (new session, zeroed time).
- Single global `TimerEngine`; swipe only changed `selectedSpaceID`.
- `TimelineView(.periodic(..., by: 0.07))`.
- Lap used `simultaneousGesture(LongPressGesture)` so long-press also lapped.
- `selectTask` required an active session.
- Live Activity `HStack` put `pause.fill` + `xmark` first; attributes held a static space name.

## Post-fix mapping

The corrective implementation removes those structures: Apple Stopwatch semantics, per-Space engines, Clock-like composition, native editors, and a timer-first Live Activity. Physical Lock Screen tap routing still requires a real iPhone.

## Post-fix Live Activity (current design — not yet re-audited on device)

Documentation and simulator preview now describe this layout; a fresh physical Lock Screen pass is still recommended.

- **Leading column:** large space-colored name, current task, elapsed via `Text(timerInterval:showsHours:true)` while running and with `pauseTime` when stopped (hh:mm:ss). Resume creates a new timer view identity so digits run again.
- **Controls:** explicit Stop or Start plus Reset (`xmark`); intents only (`openAppWhenRun = false`); surface tap opens the app without mutating the timer.
- **Trailing:** large workspace icon (SF Symbol, emoji, or monogram).
- **Background:** Space tint via `activityBackgroundTint`, not a custom mini-app chrome block.
- **Semantics:** Stop freezes and updates the activity; Start resumes; Reset archives the session and dismisses the Live Activity immediately.

## Post-fix main screen (current design)

- Full-page Space paging: header, stopwatch, controls, page dots, and tasks on one page.
- Trailing **New Space** compose page for name, tasks, color, and icons.
- Space accent as a top color wash, not giant glass cards.
- Double-tap / context menu task completion; inline add task.

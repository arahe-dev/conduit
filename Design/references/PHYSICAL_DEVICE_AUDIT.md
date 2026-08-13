# Physical-device observations

Attachments were inspected from the task (main screen, Live Activity, original concept). Bytes were not always available to commit; this file records the audit.

## Main screen (installed build)

- Two large tinted rounded rectangles on black (upper timer, lower tasks).
- Space color fills those surfaces (brown/teal), not a small accent.
- Timer `00:31`-class digits sit inside a card, not on the canvas like Clock.
- Controls sit inside the same tinted card; glass wrapping is visible.
- Task rows live in a second card rather than a list on the same black field.
- Interaction felt unsmooth: hundredths stepped; paging felt like sliding cards.

## Live Activity (installed build)

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


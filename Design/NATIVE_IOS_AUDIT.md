# Native iOS audit

Research for the ProductivityTracker corrective pass. No third-party source was copied or vendored.

## Repositories inspected

All four requested apps are currently maintained (GitHub API, 13 Aug 2026):

| Project | Evidence | Inspected for |
| --- | --- | --- |
| [Ranchero-Software/NetNewsWire](https://github.com/Ranchero-Software/NetNewsWire) | Last commit 12 Aug 2026 (`Update appcasts.`) | Feed list editing, grouped settings, absence of decorative cards |
| [mastodon/mastodon-ios](https://github.com/mastodon/mastodon-ios) | Last commit 10 Jul 2026 | UIKit table editing, swipe actions, system navigation |
| [Dimillian/IceCubesApp](https://github.com/Dimillian/IceCubesApp) | Last commit 9 Jun 2026; App Store client | SwiftUI lists, context menus, native sheets |
| [jellyfin/Swiftfin](https://github.com/jellyfin/Swiftfin) | Last commit 12 Aug 2026 (Weblate) | Settings forms, playback chrome vs content |

None were stale enough to replace.

Useful files (read on GitHub, not imported): NetNewsWire iOS Settings storyboards / inspector lists; IceCubes `App/Main/Settings`; Swiftfin Settings views. Pattern: **plain grouped lists, EditMode, swipe-to-delete, context menus**. No giant tinted content cards.

## Apple documentation consulted

- Human Interface Guidelines: layout, lists, buttons, haptics, motion
- SwiftUI: `List` + `EditMode`, context menus, `TimelineView(.animation)`
- WWDC25 “Build a UIKit app with the new design”: Liquid Glass is a **navigation/control layer**, not content wallpaper
- ActivityKit / Live Activities: timer-first lock screen presentation; `Text(timerInterval:countsDown: false)` for count-up; `ActivityUIDismissalPolicy.immediate` on end
- App Intents: explicit buttons only; default Live Activity tap opens the app
- Public Clock stopwatch behavior: Idle Lap+Start, Running Lap+Stop, Stopped Reset+Start; Stop freezes; Start resumes; Reset clears

## Principles adopted

1. Content sits on system black. Glass is not a background.
2. Stopwatch controls are independent circular buttons, not a joined glass capsule.
3. Lists use native `List` / row separators, EditMode, swipe, context menu.
4. Live Activity: elapsed time first; one explicit control; no `xmark` for Stop; no pause-on-surface-tap.
5. Motion: native paging physics; no extra springs on TabView; Reduce Motion respected.
6. Copy is functional (`Start`, `Stop`, `Reset`, `Timer is still running.`).

## Patterns explicitly rejected

- Tinted Liquid Glass on half-screen squarcles (`GlassSurface` on timer + task panel)
- `GlassEffectContainer` wrapping Lap/Start so they visually merge
- Stop = finalize/archive (previous model)
- Start after Stop = reset then new session
- Pause icon + X as primary Live Activity chrome
- Binding Pause to the whole Live Activity
- Tutorial empty-state paragraphs
- 0.07s periodic TimelineView (visible stepping)
- One global timer snapshot relabeled by swipe

## How this changed ProductivityTracker

- Per-Space `TimerEngine` ownership; swipe never relabels a running session.
- Stop freezes; Start resumes; Reset archives and clears.
- Main screen is a black Clock-like canvas. `GlassSurface` is unused on timer and task regions.
- Space accent is a 7pt indicator and page dots, not a fill.
- `TimelineView(.animation)` drives only stopwatch digits (and the live active-task time), from timestamps.
- Native Form/List editing for Spaces and tasks, including rename and reorder.
- Live Activity redesigned: timer first, one control, space name in ContentState, no pause-on-tap, immediate dismiss on Reset.

## Follow-up — Conduit branding and UX (Aug 2026)

Prior audit conclusions stand (native lists, per-Space engines, Stop/Start/Reset semantics). Subsequent work rebranded the product to **Conduit** on the home screen while keeping bundle ID `com.arahe.ProductivityTracker` and Xcode target names.

**Visual**

- App icon: liquid-glass amber **C** / conduit mark (replaces egg-timer dial).
- Main canvas: Space tint as a subtle top color wash on black, not half-screen tinted glass cards.

**Navigation**

- Full-page Space paging: timer, controls, and tasks share one page; swipe moves the whole Space.
- Trailing compose page (Home Screen–style “+” page): name, tasks, color, icon picker (SF Symbols, emoji, monogram).

**Tasks**

- Double-tap and context menu complete / uncomplete tasks.
- Inline add-task field on each Space page.

**Live Activity**

- Large space-colored name, current task, `Text(timerInterval:showsHours:true)` while running and with `pauseTime` when stopped (no ms). Resume uses a new clock identity, not an unpaused `pauseTime`.
- Stop / Start plus Reset controls; large workspace icon; background tint from Space color.
- Stop still freezes; Start resumes; Reset archives and dismisses the Live Activity immediately.


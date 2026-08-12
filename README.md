# ProductivityTracker

Private, local iPhone stopwatch for timing work across Spaces and tasks.

The product is the timer. Spaces, tasks, history, Live Activities, Shortcuts, and notifications exist only to keep that timer useful.

There is no account, no network requirement after install, no analytics, and no backend.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md).

SwiftUI + SwiftData + a timestamp-based timer state machine. Elapsed time is always `now - timestamps`, never a once-per-second counter.

## Project structure

```
project.yml
ProductivityTracker/          App, models, timer, views, intents
ProductivityTrackerLiveActivity/
ProductivityTrackerTests/
ProductivityTrackerUITests/
Scripts/ci/                   XcodeGen, simulator, IPA packaging
Scripts/windows/              IPA download helper (no credentials)
.github/workflows/ios-ci.yml
```

## Requirements

- iOS 26.0
- Xcode 26 (CI uses the GitHub-hosted `macos-26` image, currently Xcode 26.6 / iOS 26.5 SDK)
- XcodeGen 2.46.0 (pinned in `.xcodegen-version`)

## Why XcodeGen

The day-to-day environment is Windows + Cursor Cloud (Linux). The Xcode project is generated in GitHub Actions from `project.yml` so nobody has to edit `project.pbxproj` by hand.

## Development workflow

1. Edit Swift sources and `project.yml` on the Linux cloud agent or Windows.
2. Commit and push.
3. GitHub Actions on `macos-26` generates the Xcode project, compiles, tests, captures screenshots, and packages an unsigned IPA.
4. Download `ProductivityTracker-iOS-device-unsigned`.
5. Sign and install locally on Windows. See [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md).

This repository never uses a Mac owned by the app user. CI is the Xcode machine.

## CI commands

```bash
bash Scripts/ci/install-xcodegen.sh
xcodegen generate --spec project.yml
xcodebuild -project ProductivityTracker.xcodeproj -scheme ProductivityTracker \
  -destination "id=$SIM_UDID" CODE_SIGNING_ALLOWED=NO test
xcodebuild -project ProductivityTracker.xcodeproj -scheme ProductivityTracker \
  -destination "generic/platform=iOS" -configuration Release \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build
bash Scripts/ci/package-ipa.sh "$APP" artifacts
```

## Artifacts

Workflow: `.github/workflows/ios-ci.yml`  
Artifact name: `ProductivityTracker-iOS-device-unsigned`

Contains:

- `ProductivityTracker-unsigned.ipa` — **UNSIGNED — must be signed with your own Apple Account before installation**
- `SHA256SUMS.txt`
- `build-metadata.txt`
- simulator screenshots
- `TestResults.xcresult`

## Free signing

A free Apple Account can sign the IPA locally (Sideloadly). Apps expire after 7 days and must be refreshed. This project does not use TestFlight or a paid Apple Developer Program membership.

## Testing

- Unit tests cover the timer state machine, task intervals, Spaces, persistence, distraction notifications, and JSON import.
- UI tests cover launch, Start/Lap/Stop, upper-only Space paging, long-press task picker, settings/history, and a deterministic screenshot mode (`-ScreenshotMode`, frozen `00:31.42`).

## Screenshots

CI writes PNGs under `artifacts/screenshots` when `SCREENSHOT_DIR` is set. After a green run they are in the Actions artifact.

## Known limitations

- Live Activity interactive buttons use App Intents with `openAppWhenRun = true` so they work without an App Group (App Groups are not assumed for free personal signing). iOS may briefly activate the app.
- Distraction detection is a Shortcuts approximation (`Distraction Started` / `Distraction Ended`), not Screen Time / FamilyControls.
- The app cannot force system Focus on. A Focus Filter can select a Space when a Focus you configured becomes active.
- Unsigned CI artifacts cannot be installed until you sign them with your Apple Account on your computer.
- The timer UI prefers dark appearance, matching Clock’s stopwatch presentation.

## Visual references

The original annotated concept images were not in the git clone. See `Design/references/README.md`.

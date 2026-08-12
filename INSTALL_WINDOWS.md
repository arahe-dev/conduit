# Install on Windows (free Apple Account)

The IPA from GitHub Actions is **unsigned**. Sign it on this PC with your Apple Account. Do not put that password in GitHub, Cursor, or chat.

## 1. Apple Account

On iPhone or [developer.apple.com](https://developer.apple.com): register a free Apple developer account and accept Apple’s agreement if asked.

## 2. Developer Mode

iPhone: Settings → Privacy & Security → Developer Mode → On. Restart if iOS asks.

## 3. Sideloadly

Download current Sideloadly for Windows from [https://sideloadly.io](https://sideloadly.io) (`SideloadlySetup64.exe`). Sideloadly has no supported public CLI; use the app UI.

## 4. Apple device support on Windows

Sideloadly needs the **web/direct** iTunes and iCloud installers, not Microsoft Store copies.

- If Store iTunes/iCloud are installed, uninstall them.
- Install iTunes 64-bit from Apple and iCloud for Windows (non-Store), then reboot if prompted.

## 5. Connect the iPhone

USB cable. Trust this computer on the iPhone. Unlock the phone.

## 6. Download the IPA

GitHub → this repo → Actions → latest green **iOS CI** run → artifact **`ProductivityTracker-iOS-device-unsigned`**.

Inside: `ProductivityTracker-unsigned.ipa` and `SHA256SUMS.txt`.

Optional helper (no Apple credentials):

```powershell
powershell -ExecutionPolicy Bypass -File Scripts\windows\fetch-ipa.ps1
```

## 7–10. Sign and install

1. Open Sideloadly.
2. Select the iPhone.
3. Drag `ProductivityTracker-unsigned.ipa` onto Sideloadly.
4. Enter your Apple Account in Sideloadly (locally). Complete 2FA in Sideloadly/Apple prompts on this PC.
5. Start. Wait until install finishes.

Keep bundle ID `com.arahe.ProductivityTracker` so later refreshes replace the same app and keep local SwiftData.

## 11. Trust the developer

If iOS blocks launch: Settings → General → VPN & Device Management → your Apple Account → Trust.

## 12. Launch

Open ProductivityTracker. Grant notifications later, when a distraction reminder is actually useful.

## 13–15. Refresh without deleting data

Free signing expires in **7 days**. Re-sign the same bundle ID with the same Apple Account. Enable Sideloadly automatic refresh if you want weekly re-signing while this PC and iPhone can connect (often Wi-Fi sync + Sideloadly left available). Updating from a newer CI IPA is the same install flow; do not delete the app if you want history kept.

Never upload Apple passwords, 2FA codes, or signing keys to GitHub or Cursor.

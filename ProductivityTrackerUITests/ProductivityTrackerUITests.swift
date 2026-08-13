import XCTest

final class ProductivityTrackerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITests", "-ResetStore", "-InMemoryStore"]
        app.launch()
    }

    func testLaunchShowsDefaultSpace() {
        let space = app.descendants(matching: .any)["space-name"].firstMatch
        XCTAssertTrue(space.waitForExistence(timeout: 10))
        XCTAssertEqual(space.label, "Work")
        XCTAssertTrue(app.descendants(matching: .any)["timer-card"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["task-panel"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["start-stop-button"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["lap-button"].firstMatch.exists)
        XCTAssertFalse(app.descendants(matching: .any)["lap-button"].firstMatch.isEnabled)
        XCTAssertFalse(app.descendants(matching: .any)["glass-surface"].firstMatch.exists)
    }

    func testUpperSwipeChangesSpaceAndLowerSwipeDoesNot() {
        let space = app.descendants(matching: .any)["space-name"].firstMatch
        XCTAssertTrue(space.waitForExistence(timeout: 10))
        let original = space.label
        let card = app.descendants(matching: .any)["timer-card"].firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        swipe(element: card, from: 0.85, to: 0.15)
        XCTAssertTrue(space.waitForExistence(timeout: 2))
        let afterUpper = space.label
        XCTAssertNotEqual(afterUpper, original)

        let panel = app.descendants(matching: .any)["task-panel"]
        swipe(element: panel, from: 0.85, to: 0.15)
        XCTAssertEqual(space.label, afterUpper)
    }

    private func control(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    func testStartStopResetLabels() {
        let startStop = control("start-stop-button")
        XCTAssertTrue(startStop.waitForExistence(timeout: 5))
        XCTAssertEqual(startStop.label, "Start")
        startStop.tap()
        XCTAssertTrue(startStop.wait(forLabel: "Stop", timeout: 3))
        XCTAssertEqual(app.staticTexts["stopwatch-display"].value as? String, "running")
        XCTAssertTrue(control("lap-button").isEnabled)
        startStop.tap()
        XCTAssertEqual(app.staticTexts["stopwatch-display"].value as? String, "stopped")
        XCTAssertEqual(startStop.label, "Start")
        XCTAssertTrue(control("reset-button").waitForExistence(timeout: 2))
        XCTAssertEqual(control("reset-button").label, "Reset")
    }

    func testStartElapsedLapStop() {
        control("start-stop-button").tap()
        XCTAssertTrue(control("start-stop-button").wait(forLabel: "Stop", timeout: 3))
        XCTAssertTrue(app.staticTexts["stopwatch-display"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["stopwatch-display"].value as? String, "running")
        control("lap-button").tap()
        XCTAssertTrue(app.descendants(matching: .any)["task-row-Research"].firstMatch.exists)
        control("start-stop-button").tap()
        XCTAssertEqual(app.staticTexts["stopwatch-display"].value as? String, "stopped")
    }

    func testTaskTapSelectsTask() {
        control("start-stop-button").tap()
        XCTAssertTrue(control("start-stop-button").wait(forLabel: "Stop", timeout: 3))
        let email = app.descendants(matching: .any)["task-row-Email"].firstMatch
        XCTAssertTrue(email.waitForExistence(timeout: 2))
        email.tap()
        XCTAssertTrue(email.isSelected)
    }

    func testLongPressLapPresentsTaskPickerWithoutLapping() {
        control("start-stop-button").tap()
        XCTAssertTrue(control("start-stop-button").wait(forLabel: "Stop", timeout: 3))
        let deep = app.descendants(matching: .any)["task-row-Deep Work"].firstMatch
        XCTAssertTrue(deep.waitForExistence(timeout: 2))
        control("lap-button").press(forDuration: 0.85)
        let picker = app.otherElements["task-picker"].firstMatch
        let emailChoice = app.buttons["task-choice-Email"].firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 3) || emailChoice.waitForExistence(timeout: 3))
        XCTAssertFalse(app.descendants(matching: .any)["task-row-Research"].firstMatch.isSelected)
        if app.buttons["Close"].exists {
            app.buttons["Close"].tap()
        } else {
            app.swipeDown()
        }
        XCTAssertTrue(deep.isSelected || !app.descendants(matching: .any)["task-row-Research"].firstMatch.isSelected)
    }

    func testSettingsHistoryAndSpaceEditor() {
        app.buttons["settings-button"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3) || app.otherElements["settings-screen"].waitForExistence(timeout: 3))
        app.buttons["Manage Spaces"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["space-row-Work"].firstMatch.waitForExistence(timeout: 3))
        app.descendants(matching: .any)["space-row-Work"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["space-editor"].firstMatch.waitForExistence(timeout: 3))
        app.navigationBars.buttons.firstMatch.tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Session History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3) || app.otherElements["history-screen"].waitForExistence(timeout: 3))
    }

    func testControlsAreAboveHomeIndicator() {
        let start = app.descendants(matching: .any)["start-stop-button"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        let frame = start.frame
        let window = app.windows.firstMatch.frame
        XCTAssertGreaterThan(frame.minY, 40)
        XCTAssertLessThan(frame.maxY, window.maxY - 12)
    }

    func testPersistenceAcrossRelaunch() {
        app.terminate()
        app.launchArguments = ["-UITests", "-ResetStore", "-PersistStore"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["start-stop-button"].firstMatch.waitForExistence(timeout: 8))
        app.descendants(matching: .any)["start-stop-button"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["start-stop-button"].firstMatch.wait(forLabel: "Stop", timeout: 3))
        let runningValue = app.staticTexts["stopwatch-display"].value as? String
        XCTAssertEqual(runningValue, "running")
        app.terminate()
        app.launchArguments = ["-UITests", "-PersistStore"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["space-name"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["stopwatch-display"].value as? String, "running")
    }

    private func swipe(element: XCUIElement, from startX: CGFloat, to endX: CGFloat) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: startX, dy: 0.5))
        let end = element.coordinate(withNormalizedOffset: CGVector(dx: endX, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
    }
}

final class ScreenshotUITests: XCTestCase {
    func testCaptureDeterministicScreens() throws {
        let screenshotDir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] ?? NSTemporaryDirectory()
        try FileManager.default.createDirectory(atPath: screenshotDir, withIntermediateDirectories: true)

        capture(arguments: ["-UITests", "-ResetStore", "-InMemoryStore", "-ScreenshotMode", "-TimerState", "idle"], name: "01-timer-idle", directory: screenshotDir)
        capture(arguments: ["-UITests", "-ResetStore", "-InMemoryStore", "-ScreenshotMode", "-TimerState", "running"], environment: ["UITEST_ELAPSED": "31.42"], name: "02-timer-running", directory: screenshotDir)

        let running = launch(arguments: ["-UITests", "-ResetStore", "-InMemoryStore", "-ScreenshotMode", "-TimerState", "running"], environment: ["UITEST_ELAPSED": "31.42"])
        running.descendants(matching: .any)["start-stop-button"].firstMatch.tap()
        save(running.screenshot(), name: "03-timer-stopped", directory: screenshotDir)
        running.terminate()

        let pickerApp = launch(arguments: ["-UITests", "-ResetStore", "-InMemoryStore", "-ScreenshotMode", "-TimerState", "running"], environment: ["UITEST_ELAPSED": "31.42"])
        pickerApp.descendants(matching: .any)["lap-button"].firstMatch.press(forDuration: 0.8)
        sleep(1)
        save(XCUIScreen.main.screenshot(), name: "04-task-picker", directory: screenshotDir)
        pickerApp.terminate()

        let settingsApp = launch(arguments: ["-UITests", "-ResetStore", "-InMemoryStore", "-ScreenshotMode", "-TimerState", "idle"])
        settingsApp.buttons["settings-button"].tap()
        XCTAssertTrue(settingsApp.navigationBars["Settings"].waitForExistence(timeout: 3) || settingsApp.otherElements["settings-screen"].waitForExistence(timeout: 3))
        save(XCUIScreen.main.screenshot(), name: "05-settings", directory: screenshotDir)
        settingsApp.buttons["Manage Spaces"].tap()
        settingsApp.descendants(matching: .any)["space-row-Work"].firstMatch.tap()
        XCTAssertTrue(settingsApp.descendants(matching: .any)["space-editor"].firstMatch.waitForExistence(timeout: 3))
        save(XCUIScreen.main.screenshot(), name: "06-space-editor", directory: screenshotDir)
        if settingsApp.buttons["Edit"].exists {
            settingsApp.buttons["Edit"].tap()
            save(XCUIScreen.main.screenshot(), name: "07-task-reorder", directory: screenshotDir)
        }
        settingsApp.navigationBars.buttons.firstMatch.tap()
        settingsApp.navigationBars.buttons.firstMatch.tap()
        settingsApp.buttons["Session History"].tap()
        save(XCUIScreen.main.screenshot(), name: "08-history", directory: screenshotDir)
        settingsApp.terminate()

        let live = launch(arguments: ["-UITests", "-ResetStore", "-InMemoryStore", "-LiveActivityPreview"])
        XCTAssertTrue(live.descendants(matching: .any)["live-activity-preview"].firstMatch.waitForExistence(timeout: 5))
        save(live.screenshot(), name: "09-live-activity-previews", directory: screenshotDir)
        live.terminate()
    }

    private func launch(arguments: [String], environment: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launchEnvironment = environment
        app.launch()
        _ = app.descendants(matching: .any)["space-name"].firstMatch.waitForExistence(timeout: 5)
            || app.descendants(matching: .any)["live-activity-preview"].firstMatch.waitForExistence(timeout: 5)
        return app
    }

    private func capture(arguments: [String], environment: [String: String] = [:], name: String, directory: String) {
        let app = launch(arguments: arguments, environment: environment)
        save(app.screenshot(), name: name, directory: directory)
        app.terminate()
    }

    private func save(_ screenshot: XCUIScreenshot, name: String, directory: String) {
        let url = URL(fileURLWithPath: directory).appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: url)
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

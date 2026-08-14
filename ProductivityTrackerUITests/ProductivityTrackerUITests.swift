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
        XCTAssertTrue(app.descendants(matching: .any)["space-pager"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["timer-card"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["task-panel"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["start-stop-button"].firstMatch.waitForExistence(timeout: 5))
        let lap = app.descendants(matching: .any)["lap-button"].firstMatch
        XCTAssertTrue(lap.exists)
        XCTAssertFalse(lap.isEnabled)
        XCTAssertFalse(app.descendants(matching: .any)["glass-surface"].firstMatch.exists)
        XCTAssertTrue(app.staticTexts["stopwatch-display"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["save-time-button"].firstMatch.exists)
    }

    func testSwipeTimerOrTaskPanelChangesSpace() {
        let space = app.descendants(matching: .any)["space-name"].firstMatch
        XCTAssertTrue(space.waitForExistence(timeout: 10))
        XCTAssertEqual(space.label, "Work")
        let pager = app.descendants(matching: .any)["space-pager"].firstMatch
        XCTAssertTrue(pager.waitForExistence(timeout: 5))

        swipe(element: pager, from: 0.85, to: 0.15)
        XCTAssertTrue(space.waitUntilLabelEquals("Chores", timeout: 3))

        let panel = app.descendants(matching: .any)["task-panel"].firstMatch
        XCTAssertTrue(panel.waitForExistence(timeout: 2))
        swipe(element: panel, from: 0.85, to: 0.15)
        XCTAssertTrue(space.waitUntilLabelEquals("Personal", timeout: 3))
    }

    func testSwipePastLastSpaceShowsAddSpacePage() {
        let pager = app.descendants(matching: .any)["space-pager"].firstMatch
        XCTAssertTrue(pager.waitForExistence(timeout: 5))
        swipe(element: pager, from: 0.92, to: 0.05)
        swipe(element: pager, from: 0.92, to: 0.05)
        swipe(element: pager, from: 0.92, to: 0.05)
        XCTAssertTrue(app.descendants(matching: .any)["add-space-page"].firstMatch.waitForExistence(timeout: 4))
        XCTAssertTrue(app.descendants(matching: .any)["create-space-button"].firstMatch.exists)
    }

    func testTapSpaceNameOpensEditor() {
        let space = app.descendants(matching: .any)["space-name"].firstMatch
        XCTAssertTrue(space.waitForExistence(timeout: 10))
        space.tap()
        XCTAssertTrue(app.descendants(matching: .any)["space-editor"].firstMatch.waitForExistence(timeout: 4))
    }

    func testInlineAddTask() {
        let inline = app.descendants(matching: .any)["add-task-inline"].firstMatch
        XCTAssertTrue(inline.waitForExistence(timeout: 5))
        inline.tap()
        inline.typeText("New Task")
        app.descendants(matching: .any)["add-task-empty"].firstMatch.tap()
        XCTAssertTrue(app.descendants(matching: .any)["task-row-New Task"].firstMatch.waitForExistence(timeout: 3))
    }

    func testDoubleTapTaskTogglesCompletion() {
        let deep = app.descendants(matching: .any)["task-row-Deep Work"].firstMatch
        XCTAssertTrue(deep.waitForExistence(timeout: 5))
        deep.doubleTap()
        XCTAssertTrue(deep.label.lowercased().contains("completed"))
        deep.doubleTap()
        XCTAssertFalse(deep.label.lowercased().contains("completed"))
    }

    private func control(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    func testStartStopResetLabels() {
        let startStop = control("start-stop-button")
        XCTAssertTrue(startStop.waitForExistence(timeout: 5))
        XCTAssertEqual(startStop.label, "Start")
        startStop.tap()
        XCTAssertTrue(startStop.waitUntilLabelEquals("Stop", timeout: 3))
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
        XCTAssertTrue(control("start-stop-button").waitUntilLabelEquals("Stop", timeout: 3))
        XCTAssertTrue(app.staticTexts["stopwatch-display"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["stopwatch-display"].value as? String, "running")
        control("lap-button").tap()
        XCTAssertTrue(app.descendants(matching: .any)["task-row-Research"].firstMatch.exists)
        control("start-stop-button").tap()
        XCTAssertEqual(app.staticTexts["stopwatch-display"].value as? String, "stopped")
    }

    func testTaskTapSelectsTask() {
        control("start-stop-button").tap()
        XCTAssertTrue(control("start-stop-button").waitUntilLabelEquals("Stop", timeout: 3))
        let email = app.descendants(matching: .any)["task-row-Email"].firstMatch
        XCTAssertTrue(email.waitForExistence(timeout: 2))
        email.tap()
        XCTAssertTrue(email.waitUntilSelected(timeout: 2))
    }

    func testLongPressLapPresentsTaskPickerWithoutLapping() {
        control("start-stop-button").tap()
        XCTAssertTrue(control("start-stop-button").waitUntilLabelEquals("Stop", timeout: 3))
        let deep = app.descendants(matching: .any)["task-row-Deep Work"].firstMatch
        XCTAssertTrue(deep.waitForExistence(timeout: 2))
        control("lap-button").press(forDuration: 1.0)
        let picker = app.otherElements["task-picker"].firstMatch
        let emailChoice = app.buttons["task-choice-Email"].firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5) || emailChoice.waitForExistence(timeout: 5))
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
        XCTAssertTrue(app.descendants(matching: .any)["start-stop-button"].firstMatch.waitUntilLabelEquals("Stop", timeout: 3))
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
        start.press(forDuration: 0.08, thenDragTo: end)
    }
}

extension XCUIElement {
    func waitUntilLabelEquals(_ label: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    func waitUntilSelected(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "isSelected == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
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

        let addSpaceApp = launch(arguments: ["-UITests", "-ResetStore", "-InMemoryStore", "-ScreenshotMode", "-TimerState", "idle"])
        let pager = addSpaceApp.descendants(matching: .any)["space-pager"].firstMatch
        XCTAssertTrue(pager.waitForExistence(timeout: 5))
        swipe(element: pager, from: 0.92, to: 0.05)
        swipe(element: pager, from: 0.92, to: 0.05)
        swipe(element: pager, from: 0.92, to: 0.05)
        XCTAssertTrue(addSpaceApp.descendants(matching: .any)["add-space-page"].firstMatch.waitForExistence(timeout: 4))
        save(addSpaceApp.screenshot(), name: "10-add-space", directory: screenshotDir)
        addSpaceApp.terminate()

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

    private func swipe(element: XCUIElement, from startX: CGFloat, to endX: CGFloat) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: startX, dy: 0.5))
        let end = element.coordinate(withNormalizedOffset: CGVector(dx: endX, dy: 0.5))
        start.press(forDuration: 0.08, thenDragTo: end)
    }
}

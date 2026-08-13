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
        let space = app.descendants(matching: .any)["space-name"]
        XCTAssertTrue(space.waitForExistence(timeout: 10))
        XCTAssertEqual(space.label, "Work")
        XCTAssertTrue(app.descendants(matching: .any)["timer-card"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["task-panel"].exists)
        XCTAssertTrue(app.buttons["start-stop-button"].exists)
    }

    func testUpperSwipeChangesSpaceAndLowerSwipeDoesNot() {
        let space = app.descendants(matching: .any)["space-name"]
        XCTAssertTrue(space.waitForExistence(timeout: 10))
        let original = space.label
        let card = app.descendants(matching: .any)["timer-card"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        swipe(element: card, from: 0.85, to: 0.15)
        XCTAssertTrue(space.waitForExistence(timeout: 2))
        let afterUpper = space.label
        XCTAssertNotEqual(afterUpper, original)

        let panel = app.descendants(matching: .any)["task-panel"]
        swipe(element: panel, from: 0.85, to: 0.15)
        XCTAssertEqual(space.label, afterUpper)
    }

    func testStartElapsedLapStop() {
        app.buttons["start-stop-button"].tap()
        XCTAssertTrue(app.staticTexts["stopwatch-display"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["stopwatch-display"].value as? String, "running")
        app.buttons["lap-button"].tap()
        XCTAssertTrue(app.staticTexts["task-row-Research"].exists)
        app.buttons["start-stop-button"].tap()
        XCTAssertEqual(app.staticTexts["stopwatch-display"].value as? String, "stopped")
    }

    func testLongPressLapPresentsTaskPicker() {
        app.buttons["start-stop-button"].tap()
        let lap = app.buttons["lap-button"]
        lap.press(forDuration: 0.8)
        XCTAssertTrue(app.otherElements["task-picker"].waitForExistence(timeout: 3) || app.buttons["task-choice-Email"].waitForExistence(timeout: 3))
        if app.buttons["task-choice-Email"].exists {
            app.buttons["task-choice-Email"].tap()
        }
    }

    func testSettingsAndHistoryNavigation() {
        app.buttons["settings-button"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3) || app.otherElements["settings-screen"].waitForExistence(timeout: 3))
        app.buttons["Session History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3) || app.otherElements["history-screen"].waitForExistence(timeout: 3))
    }

    func testControlsAreAboveHomeIndicator() {
        let start = app.buttons["start-stop-button"]
        XCTAssertTrue(start.exists)
        let frame = start.frame
        let window = app.windows.firstMatch.frame
        XCTAssertGreaterThan(frame.minY, 40)
        XCTAssertLessThan(frame.maxY, window.maxY - 12)
    }

    func testPersistenceAcrossRelaunch() {
        app.terminate()
        app.launchArguments = ["-UITests", "-ResetStore", "-PersistStore"]
        app.launch()
        XCTAssertTrue(app.buttons["start-stop-button"].waitForExistence(timeout: 5))
        app.buttons["start-stop-button"].tap()
        let runningValue = app.staticTexts["stopwatch-display"].value as? String
        XCTAssertEqual(runningValue, "running")
        app.terminate()
        app.launchArguments = ["-UITests", "-PersistStore"]
        app.launch()
        XCTAssertTrue(app.staticTexts["space-name"].waitForExistence(timeout: 5))
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
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "-ResetStore", "-InMemoryStore", "-ScreenshotMode"]
        app.launchEnvironment["UITEST_ELAPSED"] = "31.42"
        app.launch()
        XCTAssertTrue(app.staticTexts["space-name"].waitForExistence(timeout: 5))

        let screenshotDir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] ?? NSTemporaryDirectory()
        try FileManager.default.createDirectory(atPath: screenshotDir, withIntermediateDirectories: true)

        save(app.screenshot(), name: "01-timer-running", directory: screenshotDir)

        app.buttons["lap-button"].press(forDuration: 0.8)
        sleep(1)
        save(XCUIScreen.main.screenshot(), name: "02-task-picker", directory: screenshotDir)
        if app.buttons["Close"].exists {
            app.buttons["Close"].tap()
        } else {
            app.swipeDown()
        }

        app.buttons["settings-button"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3) || app.otherElements["settings-screen"].waitForExistence(timeout: 3))
        save(XCUIScreen.main.screenshot(), name: "03-settings", directory: screenshotDir)
        app.buttons["Session History"].tap()
        save(XCUIScreen.main.screenshot(), name: "04-history", directory: screenshotDir)
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

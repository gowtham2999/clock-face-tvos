//
//  Clock_FaceUITests.swift
//  Clock FaceUITests
//
//  Created by Web2 on 06/10/26.
//

import XCTest

final class Clock_FaceUITests: XCTestCase {
    private let remote = XCUIRemote.shared
    private let tabs = ["Clock", "Faces", "Sports", "World"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Clock

    @MainActor
    func testTopBarAutoHidesAndRemoteSwitchesFaces() throws {
        let app = launch()
        let clockTab = app.buttons["Clock"]
        XCTAssertTrue(clockTab.waitForExistence(timeout: 5))

        expectation(for: NSPredicate(format: "isEnabled == false"), evaluatedWith: clockTab)
        waitForExpectations(timeout: 10)
        attachScreenshot(app, named: "clock-classic")

        let announcement = app.staticTexts["faceAnnouncement"]
        remote.press(.right)
        XCTAssertTrue(announcement.waitForExistence(timeout: 2))
        XCTAssertEqual(announcement.label, "Essential")
        attachScreenshot(app, named: "clock-essential")

        remote.press(.right)
        XCTAssertEqual(announcement.label, "Tint")
        remote.press(.left)
        XCTAssertEqual(announcement.label, "Essential")

        remote.press(.select)
        expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: clockTab)
        waitForExpectations(timeout: 3)
    }

    @MainActor
    func testReminderAlertShowsAndDismisses() throws {
        let app = launch(extraArguments: ["-UITestShowReminder", "YES"])
        let event = app.staticTexts["reminderEvent"]
        XCTAssertTrue(event.waitForExistence(timeout: 5))
        XCTAssertEqual(event.label, "United States Grand Prix")
        attachScreenshot(app, named: "reminder-alert")

        remote.press(.select)
        XCTAssertTrue(event.waitForNonExistence(timeout: 3))
    }

    // MARK: - Faces

    @MainActor
    func testGalleryCustomisesAndSetsAFace() throws {
        let app = launch()
        select(tab: "Faces", in: app)
        XCTAssertTrue(app.staticTexts["MY FACES"].waitForExistence(timeout: 3))
        attachScreenshot(app, named: "faces-gallery")

        // My Faces row, then the Analog row: Classic, Essential, Station.
        press(.down, times: 2)
        press(.left, times: 4)
        press(.right, times: 2)
        let station = app.buttons["Station"].firstMatch
        XCTAssertTrue(station.hasFocus, focusedLabel(app))
        remote.press(.select)

        let setAsClock = app.buttons["Set as Clock"]
        XCTAssertTrue(setAsClock.waitForExistence(timeout: 3))

        // Up to the swatches, left to Gold, right twice to Navy.
        press(.up, times: 3)
        press(.left, times: 4)
        press(.right, times: 2)
        let navy = app.buttons["Navy"]
        XCTAssertTrue(navy.hasFocus, focusedLabel(app))
        remote.press(.select)
        XCTAssertTrue(navy.isSelected)
        attachScreenshot(app, named: "face-detail-station-navy")

        press(.down, times: 1)
        XCTAssertTrue(setAsClock.hasFocus, focusedLabel(app))
        remote.press(.select)

        let canvas = app.descendants(matching: .any)["clockCanvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 3))
        XCTAssertEqual(canvas.label, "Clock face, Station")
        attachScreenshot(app, named: "clock-station")
    }

    // MARK: - Sports

    @MainActor
    func testF1ReminderCanBeToggled() throws {
        let app = launch()
        select(tab: "Sports", in: app)
        XCTAssertTrue(app.staticTexts["weekendName"].waitForExistence(timeout: 5))
        attachScreenshot(app, named: "sports-f1")

        // Into the sidebar, then across to the first session's reminder button.
        remote.press(.down)
        remote.press(.right)
        let focused = focusedElement(in: app)
        XCTAssertTrue(focused.label.hasSuffix("reminder"), focusedLabel(app))

        let button = app.buttons[focused.label]
        let before = try XCTUnwrap(button.value as? String)
        let after = before == "On" ? "Off" : "On"

        remote.press(.select)
        waitForValue(after, of: button)
        attachScreenshot(app, named: "sports-f1-reminder")

        remote.press(.select)
        waitForValue(before, of: button)
    }

    // MARK: - World

    @MainActor
    func testWorldClockShowsSixCitiesAndOpensThePicker() throws {
        let app = launch()
        select(tab: "World", in: app)

        let cards = app.descendants(matching: .any).matching(identifier: "cityCard")
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(cards.count, 6)
        attachScreenshot(app, named: "world-clock")

        remote.press(.down)
        XCTAssertTrue(app.buttons["Edit Cities"].hasFocus, focusedLabel(app))
        remote.press(.select)
        XCTAssertTrue(app.buttons["Tokyo"].waitForExistence(timeout: 3))
        attachScreenshot(app, named: "world-city-picker")

        remote.press(.menu)
        XCTAssertTrue(app.buttons["Tokyo"].waitForNonExistence(timeout: 3))
    }

    // MARK: - Settings

    @MainActor
    func testSettingsPanelSwitchesTheme() throws {
        let app = launch()
        moveFocusIntoTopBar(of: app)
        press(.right, times: 5)
        let gear = app.buttons["Settings"]
        XCTAssertTrue(gear.hasFocus, focusedLabel(app))
        remote.press(.select)

        let light = app.buttons["Light"]
        XCTAssertTrue(light.waitForExistence(timeout: 3))
        attachScreenshot(app, named: "settings-panel")

        // Down from the gear lands in the panel's top (theme) row; settle on Light.
        remote.press(.down)
        press(.left, times: 2)
        remote.press(.right)
        XCTAssertTrue(light.hasFocus, focusedLabel(app))
        remote.press(.select)
        attachScreenshot(app, named: "settings-light-theme")

        remote.press(.menu)
        XCTAssertTrue(light.waitForNonExistence(timeout: 3))
    }

    // MARK: - Helpers

    /// Argument-domain defaults pin a known starting state regardless of earlier runs.
    private func launch(face: String = "analogClassic", extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-faceType", face,
            "-myFaces", "(analogClassic,essential,tint,flip)",
            "-theme", "dark", "-uses24HourTime", "NO",
            "-chimeSource", "mute", "-volume", "1", "-pixelShiftEnabled", "NO",
        ] + extraArguments
        app.launch()
        return app
    }

    /// From the Clock tab, presses Up until focus reaches the top bar. Right after
    /// launch the first press can arrive before focus has settled on the clock.
    private func moveFocusIntoTopBar(of app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Clock"].waitForExistence(timeout: 5))
        let barItems = tabs + ["Settings"]
        for _ in 0..<3 {
            remote.press(.up)
            if barItems.contains(where: { app.buttons[$0].hasFocus }) { return }
        }
        XCTFail("Couldn't move focus into the top bar. \(focusedLabel(app))")
    }

    /// From the Clock tab, moves into the top bar and selects `tab`.
    private func select(tab: String, in app: XCUIApplication) {
        moveFocusIntoTopBar(of: app)
        press(.left, times: tabs.count)
        press(.right, times: tabs.firstIndex(of: tab)!)
        XCTAssertTrue(app.buttons[tab].hasFocus, focusedLabel(app))
        remote.press(.select)
    }

    private func press(_ button: XCUIRemote.Button, times: Int) {
        for _ in 0..<times {
            remote.press(button)
        }
    }

    private func waitForValue(_ value: String, of element: XCUIElement, timeout: TimeInterval = 3) {
        expectation(for: NSPredicate(format: "value == %@", value), evaluatedWith: element)
        waitForExpectations(timeout: timeout)
    }

    private func focusedElement(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).element(matching: NSPredicate(format: "hasFocus == true"))
    }

    private func focusedLabel(_ app: XCUIApplication) -> String {
        let focused = focusedElement(in: app)
        return focused.exists ? "Focused: \(focused.label)" : "Nothing focused"
    }

    private func attachScreenshot(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

//
//  Clock_FaceUITests.swift
//  Clock FaceUITests
//
//  Created by Web2 on 06/10/26.
//

import XCTest

final class Clock_FaceUITests: XCTestCase {
    private let remote = XCUIRemote.shared

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSettingsPanelFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = baseArguments + ["-faceType", "analogClassic"]
        app.launch()

        XCTAssertTrue(app.buttons["Watch"].waitForExistence(timeout: 5))
        attachScreenshot(app, named: "1-watch-face")

        // Watch -> Focus -> World Time -> Settings, then open the panel.
        press(.right, times: 3)
        XCTAssertTrue(app.buttons["Settings"].hasFocus, focusedLabel(app))
        remote.press(.select)

        let green = app.buttons["Green"]
        XCTAssertTrue(green.waitForExistence(timeout: 3))
        attachScreenshot(app, named: "2-panel-open")

        // Down past the Face and Theme rows into the swatches, all the way left (White),
        // then right twice to Green.
        press(.down, times: 3)
        press(.left, times: 5)
        press(.right, times: 2)
        XCTAssertTrue(green.hasFocus, focusedLabel(app))
        remote.press(.select)
        XCTAssertTrue(green.isSelected)

        // Down past the 12/24-hour row and the sound picker to the volume bar, then step it down 20%.
        let volume = app.otherElements["Volume"]
        press(.down, times: 3)
        XCTAssertTrue(volume.hasFocus, focusedLabel(app))
        press(.left, times: 4)
        XCTAssertEqual(volume.value as? String, "80%")
        attachScreenshot(app, named: "3-green-volume-80")

        // Menu closes the panel.
        remote.press(.menu)
        XCTAssertTrue(green.waitForNonExistence(timeout: 3))

        // Settings button is disabled on placeholder tabs.
        press(.left, times: 3)
        remote.press(.right)
        XCTAssertTrue(app.buttons["Focus"].hasFocus, focusedLabel(app))
        remote.press(.select)
        XCTAssertTrue(app.staticTexts["Coming soon"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Settings"].isEnabled)
        attachScreenshot(app, named: "4-placeholder-tab")
    }

    @MainActor
    func testFlipFace() throws {
        let app = XCUIApplication()
        app.launchArguments = baseArguments + ["-faceType", "flip"]
        app.launch()

        XCTAssertTrue(app.staticTexts["flipHours"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["flipMinutes"].exists)
        XCTAssertTrue(hasPeriodLabel(app), "12-hour time should show AM/PM")
        attachScreenshot(app, named: "5-flip-dark-12h")

        press(.right, times: 3)
        remote.press(.select)
        XCTAssertTrue(app.buttons["24-Hour"].waitForExistence(timeout: 3))

        // Face -> Theme -> swatches -> 12/24-hour row; pick 24-Hour.
        press(.down, times: 4)
        remote.press(.right)
        XCTAssertTrue(app.buttons["24-Hour"].hasFocus, focusedLabel(app))
        remote.press(.select)
        XCTAssertFalse(hasPeriodLabel(app), "24-hour time should hide AM/PM")

        // Up past the swatches to the Theme row; pick Light.
        press(.up, times: 2)
        remote.press(.right)
        XCTAssertTrue(app.buttons["Light"].hasFocus, focusedLabel(app))
        remote.press(.select)

        remote.press(.menu)
        XCTAssertTrue(app.buttons["24-Hour"].waitForNonExistence(timeout: 3))
        attachScreenshot(app, named: "6-flip-light-24h")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    /// Argument-domain defaults pin the starting settings regardless of earlier runs.
    private let baseArguments = [
        "-theme", "dark", "-uses24HourTime", "NO",
        "-accentColor", "yellow", "-chimeSource", "watch", "-volume", "1",
    ]

    private func hasPeriodLabel(_ app: XCUIApplication) -> Bool {
        app.staticTexts["AM"].exists || app.staticTexts["PM"].exists
    }

    private func press(_ button: XCUIRemote.Button, times: Int) {
        for _ in 0..<times {
            remote.press(button)
        }
    }

    private func focusedLabel(_ app: XCUIApplication) -> String {
        let focused = app.descendants(matching: .any).element(matching: NSPredicate(format: "hasFocus == true"))
        return focused.exists ? "Focused: \(focused.label)" : "Nothing focused"
    }

    private func attachScreenshot(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

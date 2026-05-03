import XCTest

final class FlexoraUITests: XCTestCase {
    func testVideoModuleAppearsInChooser() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Video Frame Extraction"].waitForExistence(timeout: 2))
    }

    func testWorkspaceShowsImportActions() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Video Frame Extraction"].click()

        let exportButton = app.buttons["video-export-button"]

        XCTAssertTrue(app.buttons["Import Video"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Drop a video here"].exists)
        XCTAssertTrue(app.staticTexts["No Video Loaded"].exists)
        XCTAssertTrue(exportButton.exists)
        XCTAssertFalse(exportButton.isEnabled)
    }

    func testExportPanelShowsThreeFormats() {
        let app = XCUIApplication()
        app.launchArguments = ["-flexora-ui-sample-candidates", "1"]
        app.launch()
        app.buttons["Video Frame Extraction"].click()
        app.buttons["Export"].click()
        XCTAssertTrue(app.buttons["PNG"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["JPEG"].exists)
        XCTAssertTrue(app.buttons["HEIC"].exists)
    }
}

import XCTest

final class FlexoraUITests: XCTestCase {
    func testLaunchesToModuleChooser() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["module-chooser-placeholder"].waitForExistence(timeout: 2))
    }
}

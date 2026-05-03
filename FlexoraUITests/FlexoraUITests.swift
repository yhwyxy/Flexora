import XCTest

final class FlexoraUITests: XCTestCase {
    func testLaunchesToModuleChooser() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Choose a Module"].waitForExistence(timeout: 2))
    }
}

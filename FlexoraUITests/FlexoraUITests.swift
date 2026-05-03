import XCTest

final class FlexoraUITests: XCTestCase {
    func testVideoModuleAppearsInChooser() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Video Frame Extraction"].waitForExistence(timeout: 2))
    }
}

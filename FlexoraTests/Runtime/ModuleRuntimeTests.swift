import Testing
@testable import Flexora

struct ModuleRuntimeTests {
    @Test func smoke() {
        #expect(ContentView.placeholderTitle == "Choose a Module")
    }
}

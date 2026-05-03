import Testing
@testable import Flexora

struct ToolSessionTests {
    @MainActor
    @Test func selectingModuleUpdatesRoute() {
        let model = AppModel(runtime: ModuleRuntime())

        model.route = .moduleChooser
        model.openModule(withID: "video")

        #expect(model.route == .workspace(moduleID: "video"))
    }
}

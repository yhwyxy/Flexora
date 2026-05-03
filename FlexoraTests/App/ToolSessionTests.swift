import Testing
import SwiftUI
@testable import Flexora

struct ToolSessionTests {
    @MainActor
    @Test func selectingModuleUpdatesRoute() {
        let runtime = ModuleRuntime()
        let module = TestAppModule(id: "video")
        let model = AppModel(runtime: runtime)

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)

        model.route = .moduleChooser
        model.openModule(withID: "video")

        #expect(model.route == .workspace(moduleID: "video"))
    }

    @MainActor
    @Test func openingUnavailableModuleLeavesChooserRoute() {
        let model = AppModel(runtime: ModuleRuntime())

        model.route = .moduleChooser
        model.openModule(withID: "video")

        #expect(model.route == .moduleChooser)
        #expect(model.activeSession == nil)
    }

    @MainActor
    @Test func syncStateFromRuntimeClearsInactiveWorkspace() {
        let runtime = ModuleRuntime()
        let module = TestAppModule(id: "video")
        let model = AppModel(runtime: runtime)

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)
        model.openModule(withID: "video")

        runtime.setModuleEnabled("video", isEnabled: false)

        #expect(model.route == .moduleChooser)
        #expect(model.activeSession == nil)
    }

    @MainActor
    @Test func reopeningActiveModulePreservesSession() {
        let runtime = ModuleRuntime()
        let module = TestAppModule(id: "video")
        let model = AppModel(runtime: runtime)

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)
        model.openModule(withID: "video")
        let originalSession = model.activeSession

        model.openModule(withID: "video")

        #expect(model.route == .workspace(moduleID: "video"))
        #expect(model.activeSession === originalSession)
    }
}

private final class TestAppModule: ToolModule {
    let descriptor: ModuleDescriptor

    init(id: String) {
        descriptor = ModuleDescriptor(
            id: id,
            name: id.capitalized,
            capabilities: []
        )
    }

    func load() {}

    func unload() {}

    func makeWorkspaceView(session: ToolSession) -> AnyView {
        AnyView(EmptyView())
    }
}

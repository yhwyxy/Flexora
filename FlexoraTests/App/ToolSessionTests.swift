import Testing
import SwiftUI
@testable import Flexora

@MainActor
struct ToolSessionTests {
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

    @Test func openingUnavailableModuleLeavesChooserRoute() {
        let model = AppModel(runtime: ModuleRuntime())

        model.route = .moduleChooser
        model.openModule(withID: "video")

        #expect(model.route == .moduleChooser)
        #expect(model.activeSession == nil)
    }

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

    @Test func initSynchronizesWithActiveRuntimeModule() {
        let runtime = ModuleRuntime()
        let module = TestAppModule(id: "video")

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)
        runtime.activateModule(withID: "video")

        let model = AppModel(runtime: runtime)

        #expect(model.route == .workspace(moduleID: "video"))
        #expect(model.activeSession?.moduleID == "video")
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

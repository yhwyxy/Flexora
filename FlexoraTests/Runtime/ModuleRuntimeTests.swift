import Testing
import SwiftUI
@testable import Flexora

@MainActor
struct ModuleRuntimeTests {
    @Test func enabledModuleAppearsInAvailableList() {
        let runtime = ModuleRuntime()
        let module = TestModule(id: "video")

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)

        #expect(runtime.availableModules.map(\.id) == ["video"])
    }

    @Test func disablingActiveModuleUnloadsIt() {
        let runtime = ModuleRuntime()
        let module = TestModule(id: "video")

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)
        _ = runtime.activateModule(withID: "video")
        runtime.setModuleEnabled("video", isEnabled: false)

        #expect(module.loadCallCount == 1)
        #expect(module.unloadCallCount == 1)
        #expect(runtime.activeModuleID == nil)
    }

    @Test func switchingActiveModulesUnloadsPreviousModule() {
        let runtime = ModuleRuntime()
        let firstModule = TestModule(id: "video")
        let secondModule = TestModule(id: "audio")

        runtime.register(module: firstModule)
        runtime.register(module: secondModule)
        runtime.setModuleEnabled("video", isEnabled: true)
        runtime.setModuleEnabled("audio", isEnabled: true)

        _ = runtime.activateModule(withID: "video")
        _ = runtime.activateModule(withID: "audio")

        #expect(firstModule.loadCallCount == 1)
        #expect(firstModule.unloadCallCount == 1)
        #expect(secondModule.loadCallCount == 1)
        #expect(secondModule.unloadCallCount == 0)
        #expect(runtime.activeModuleID == "audio")
    }

    @Test func reactivatingActiveModuleIsIdempotent() {
        let runtime = ModuleRuntime()
        let module = TestModule(id: "video")

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)

        _ = runtime.activateModule(withID: "video")
        _ = runtime.activateModule(withID: "video")

        #expect(module.loadCallCount == 1)
        #expect(module.unloadCallCount == 0)
        #expect(runtime.activeModuleID == "video")
    }
}

private final class TestModule: ToolModule {
    let descriptor: ModuleDescriptor
    private(set) var loadCallCount = 0
    private(set) var unloadCallCount = 0

    init(id: String) {
        descriptor = ModuleDescriptor(
            id: id,
            name: id.capitalized,
            capabilities: []
        )
    }

    func load() {
        loadCallCount += 1
    }

    func unload() {
        unloadCallCount += 1
    }

    func makeWorkspaceView(session: ToolSession) -> AnyView {
        AnyView(EmptyView())
    }
}

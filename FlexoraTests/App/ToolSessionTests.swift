import Testing
import SwiftUI
@testable import Flexora

@MainActor
struct ToolSessionTests {
    @Test func openingModuleRoutesToDefaultWorkflowTask() {
        let runtime = ModuleRuntime()
        let store = WorkflowStore()
        let module = TestAppModule(id: "video")
        let model = AppModel(runtime: runtime, workflowStore: store)

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)

        model.openModule(withID: "video")

        #expect(model.route == .task(workflowID: "module.video.default"))
        #expect(model.activeSession?.moduleID == "video")
        #expect(store.workflows.map(\.id) == ["module.video.default"])
    }

    @Test func openingUnavailableModuleLeavesCurrentRoute() {
        let model = AppModel(runtime: ModuleRuntime(), workflowStore: WorkflowStore(), route: .modules)

        model.openModule(withID: "video")

        #expect(model.route == .modules)
        #expect(model.activeSession == nil)
    }

    @Test func openingMultiStepWorkflowRoutesByWorkflowIDWithoutSession() {
        let runtime = ModuleRuntime()
        let store = WorkflowStore()
        let model = AppModel(runtime: runtime, workflowStore: store)

        store.save(
            WorkflowRecord(
                id: "workflow.video-storyboard",
                title: "Video Storyboard",
                summary: "Generate a storyboard from a clip.",
                source: .userAuthored,
                tags: [],
                nodes: [
                    WorkflowNode(id: "video-node", moduleID: "video", title: "Extract Frames"),
                    WorkflowNode(id: "image-node", moduleID: "images", title: "Build Contact Sheet"),
                ],
                connections: []
            )
        )

        model.openWorkflow(withID: "workflow.video-storyboard")

        #expect(model.activeSession == nil)
        #expect(model.route == .task(workflowID: "workflow.video-storyboard"))
    }

    @Test func reopeningActiveSingleModuleWorkflowPreservesSession() {
        let runtime = ModuleRuntime()
        let store = WorkflowStore()
        let module = TestAppModule(id: "video")
        let model = AppModel(runtime: runtime, workflowStore: store)

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)
        store.save(
            WorkflowRecord(
                id: "workflow.video-storyboard",
                title: "Video Storyboard",
                summary: "Generate a storyboard from a clip.",
                source: .userAuthored,
                tags: [],
                nodes: [
                    WorkflowNode(id: "video-node", moduleID: "video", title: "Extract Frames"),
                ],
                connections: []
            )
        )

        model.openWorkflow(withID: "workflow.video-storyboard")
        let originalSession = model.activeSession

        model.openWorkflow(withID: "workflow.video-storyboard")

        #expect(model.route == .task(workflowID: "workflow.video-storyboard"))
        #expect(model.activeSession === originalSession)
    }

    @Test func editingWorkflowRoutesToWorkflowEditor() {
        let store = WorkflowStore()
        let model = AppModel(runtime: ModuleRuntime(), workflowStore: store)

        store.save(
            WorkflowRecord(
                id: "workflow.video-storyboard",
                title: "Video Storyboard",
                summary: "Generate a storyboard from a clip.",
                source: .userAuthored,
                tags: [],
                nodes: [
                    WorkflowNode(id: "video-node", moduleID: "video", title: "Extract Frames"),
                ],
                connections: []
            )
        )

        model.editWorkflow(withID: "workflow.video-storyboard")

        #expect(model.route == .workflowEditor(workflowID: "workflow.video-storyboard"))
        #expect(model.activeSession == nil)
    }

    @Test func syncStateFromRuntimeResynchronizesDefaultWorkflowsAndClearsInvalidSession() {
        let runtime = ModuleRuntime()
        let store = WorkflowStore()
        let model = AppModel(runtime: runtime, workflowStore: store)
        let videoModule = TestAppModule(id: "video")
        let audioModule = TestAppModule(id: "audio")

        runtime.register(module: videoModule)
        runtime.setModuleEnabled("video", isEnabled: true)
        model.openModule(withID: "video")

        runtime.register(module: audioModule)
        runtime.setModuleEnabled("video", isEnabled: false)
        model.syncStateFromRuntime()

        #expect(model.route == .task(workflowID: "module.video.default"))
        #expect(model.activeSession == nil)
        #expect(store.workflows.map(\.id).sorted() == [
            "module.audio.default",
            "module.video.default",
        ])
    }

    @Test func initSynchronizesWithActiveRuntimeModuleAndDefaultWorkflow() {
        let runtime = ModuleRuntime()
        let store = WorkflowStore()
        let module = TestAppModule(id: "video")

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)
        runtime.activateModule(withID: "video")

        let model = AppModel(runtime: runtime, workflowStore: store)

        #expect(model.route == .task(workflowID: "module.video.default"))
        #expect(model.activeSession?.moduleID == "video")
        #expect(store.workflows.map(\.id) == ["module.video.default"])
    }
}

private final class TestAppModule: ToolModule {
    let descriptor: ModuleDescriptor

    init(id: String) {
        descriptor = ModuleDescriptor(
            id: id,
            name: id.capitalized,
            capabilities: [.workspace]
        )
    }

    func load() {}

    func unload() {}

    func makeWorkspaceView(session: ToolSession) -> AnyView {
        AnyView(EmptyView())
    }
}

import Testing
import SwiftUI
@testable import Flexora

@MainActor
struct ToolSessionTests {
    @Test func workflowFirstTopLevelRoutesAreDistinct() {
        #expect(AppRoute.home != .workshop)
        #expect(AppRoute.home != .modules)
        #expect(AppRoute.workshop != .modules)
        #expect(AppRoute.home.topLevelRoute == AppRoute.TopLevelRoute.home)
        #expect(AppRoute.workshop.topLevelRoute == AppRoute.TopLevelRoute.workshop)
        #expect(AppRoute.modules.topLevelRoute == AppRoute.TopLevelRoute.modules)
        #expect(AppRoute.home.workflowID == nil)
        #expect(AppRoute.workshop.workflowID == nil)
        #expect(AppRoute.modules.workflowID == nil)
        #expect(AppRoute.home.isTask == false)
        #expect(AppRoute.workshop.isTask == false)
        #expect(AppRoute.modules.isTask == false)
        switch AppRoute.home {
        case .home:
            break
        default:
            Issue.record("Expected AppRoute.home to be the .home case.")
        }
        switch AppRoute.workshop {
        case .workshop:
            break
        default:
            Issue.record("Expected AppRoute.workshop to be the .workshop case.")
        }
        switch AppRoute.modules {
        case .modules:
            break
        default:
            Issue.record("Expected AppRoute.modules to be the .modules case.")
        }
    }

    @Test func taskRouteRetainsWorkflowIdentityForDefaultWorkflow() {
        #expect(AppRoute.task(workflowID: "module.video.default").workflowID == "module.video.default")
        #expect(AppRoute.task(workflowID: "module.video.default").topLevelRoute == nil)
        #expect(AppRoute.task(workflowID: "module.video.default").isTask)
        #expect(AppRoute.task(workflowID: "module.video.default").isWorkflowEditor == false)
        if case let .task(workflowID: workflowID) = AppRoute.task(workflowID: "module.video.default") {
            #expect(workflowID == "module.video.default")
        } else {
            Issue.record("Expected AppRoute.task(workflowID:) to produce the .task case.")
        }
    }

    @Test func workflowEditorRouteRetainsWorkflowIdentity() {
        #expect(AppRoute.workflowEditor(workflowID: "workflow.video-storyboard").workflowID == "workflow.video-storyboard")
        #expect(AppRoute.workflowEditor(workflowID: "workflow.video-storyboard").topLevelRoute == nil)
        #expect(AppRoute.workflowEditor(workflowID: "workflow.video-storyboard").isTask == false)
        #expect(AppRoute.workflowEditor(workflowID: "workflow.video-storyboard").isWorkflowEditor)
        if case let .workflowEditor(workflowID: workflowID) = AppRoute.workflowEditor(workflowID: "workflow.video-storyboard") {
            #expect(workflowID == "workflow.video-storyboard")
        } else {
            Issue.record("Expected AppRoute.workflowEditor(workflowID:) to produce the .workflowEditor case.")
        }
    }

    @Test func openingModuleRoutesToDefaultWorkflowTask() {
        let runtime = ModuleRuntime()
        let store = WorkflowStore()
        let module = TestAppModule(id: "video")
        let model = AppModel(runtime: runtime, workflowStore: store)

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)

        model.openModule(withID: "video")

        #expect(model.route == .task(workflowID: "module.video.default"))
        if case let .task(workflowID: workflowID) = model.route {
            #expect(workflowID == "module.video.default")
        } else {
            Issue.record("Expected module opening to route to the .task case.")
        }
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
        if case let .task(workflowID: workflowID) = model.route {
            #expect(workflowID == "workflow.video-storyboard")
        } else {
            Issue.record("Expected workflow opening to route to the .task case.")
        }
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
        if case let .task(workflowID: workflowID) = model.route {
            #expect(workflowID == "workflow.video-storyboard")
        } else {
            Issue.record("Expected workflow reopening to preserve the .task case.")
        }
        #expect(model.activeSession === originalSession)
    }

    @Test func openingDifferentSingleModuleWorkflowCreatesFreshSession() {
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
        store.save(
            WorkflowRecord(
                id: "workflow.video-preview",
                title: "Video Preview",
                summary: "Build a preview from a clip.",
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

        model.openWorkflow(withID: "workflow.video-preview")

        #expect(model.route == .task(workflowID: "workflow.video-preview"))
        #expect(model.activeSession?.moduleID == "video")
        #expect(model.activeSession !== originalSession)
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
        if case let .workflowEditor(workflowID: workflowID) = model.route {
            #expect(workflowID == "workflow.video-storyboard")
        } else {
            Issue.record("Expected workflow editing to route to the .workflowEditor case.")
        }
        #expect(model.activeSession == nil)
    }

    @Test func sidebarActiveDestinationTracksOnlyTopLevelRoutes() {
        let runtime = ModuleRuntime()
        let store = WorkflowStore()
        let module = TestAppModule(id: "video")
        let model = AppModel(runtime: runtime, workflowStore: store)

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)

        model.showHome()
        #expect(AppSidebarView(model: model).activeDestination == .home)

        model.showWorkshop()
        #expect(AppSidebarView(model: model).activeDestination == .workshop)

        model.showModules()
        #expect(AppSidebarView(model: model).activeDestination == .modules)

        model.openModule(withID: "video")
        #expect(AppSidebarView(model: model).activeDestination == nil)

        model.editWorkflow(withID: "module.video.default")
        #expect(AppSidebarView(model: model).activeDestination == nil)
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

    @Test func navigatingToTopLevelRoutesClearsActiveSession() {
        let runtime = ModuleRuntime()
        let store = WorkflowStore()
        let module = TestAppModule(id: "video")
        let model = AppModel(runtime: runtime, workflowStore: store)

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)

        model.openModule(withID: "video")
        #expect(model.activeSession?.moduleID == "video")

        model.showHome()
        #expect(model.route == .home)
        #expect(model.activeSession == nil)

        model.openModule(withID: "video")
        #expect(model.activeSession?.moduleID == "video")

        model.showWorkshop()
        #expect(model.route == .workshop)
        #expect(model.activeSession == nil)

        model.openModule(withID: "video")
        #expect(model.activeSession?.moduleID == "video")

        model.showModules()
        #expect(model.route == .modules)
        #expect(model.activeSession == nil)
    }

    @Test func syncStateFromRuntimeDoesNotForceRouteFromTopLevelNavigation() {
        let runtime = ModuleRuntime()
        let store = WorkflowStore()
        let module = TestAppModule(id: "video")
        let model = AppModel(runtime: runtime, workflowStore: store, route: .home)

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)
        runtime.activateModule(withID: "video")
        model.syncStateFromRuntime()

        #expect(model.route == .home)
        #expect(model.activeSession == nil)
        #expect(store.workflows.map(\.id) == ["module.video.default"])
    }

    @Test func initSynchronizesWorkflowsWithoutForcingTaskRoute() {
        let runtime = ModuleRuntime()
        let store = WorkflowStore()
        let module = TestAppModule(id: "video")

        runtime.register(module: module)
        runtime.setModuleEnabled("video", isEnabled: true)
        runtime.activateModule(withID: "video")

        let model = AppModel(runtime: runtime, workflowStore: store, route: .modules)

        #expect(model.route == .modules)
        #expect(model.activeSession == nil)
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

import Testing
import SwiftUI
@testable import Flexora

@MainActor
struct WorkflowStoreTests {
    @Test func createsOneDefaultWorkflowPerRegisteredModule() throws {
        let runtime = ModuleRuntime()
        runtime.register(module: TestWorkflowModule(
            id: "audio",
            name: "Audio Extraction",
            summary: "Extract an audio track from a source clip."
        ))
        runtime.register(module: TestWorkflowModule(
            id: "video",
            name: "Video Frame Extraction",
            summary: "Find strong still frames from a video."
        ))
        runtime.setModuleEnabled("audio", isEnabled: true)

        let store = WorkflowStore()
        store.synchronizeDefaultWorkflows(with: runtime)

        #expect(store.workflows.map(\.id).sorted() == [
            "module.audio.default",
            "module.video.default",
        ])
        #expect(store.workflows.map(\.title).sorted() == [
            "Audio Extraction",
            "Video Frame Extraction",
        ])
        #expect(store.workflows.map(\.summary).sorted() == [
            "Extract an audio track from a source clip.",
            "Find strong still frames from a video.",
        ])

        let audioWorkflow = try #require(store.workflows.first { $0.id == "module.audio.default" })
        let videoWorkflow = try #require(store.workflows.first { $0.id == "module.video.default" })
        #expect(store.availability(for: audioWorkflow, with: runtime) == .available)
        #expect(store.availability(for: videoWorkflow, with: runtime) == .unavailable(requiredModuleIDs: ["video"]))
    }

    @Test func synchronizeDefaultWorkflowsDoesNotDuplicateExistingDefaults() {
        let runtime = ModuleRuntime()
        runtime.register(module: TestWorkflowModule(
            id: "video",
            name: "Video Frame Extraction",
            summary: "Find strong still frames from a video."
        ))
        runtime.setModuleEnabled("video", isEnabled: true)

        let store = WorkflowStore()
        store.synchronizeDefaultWorkflows(with: runtime)
        store.synchronizeDefaultWorkflows(with: runtime)

        #expect(store.workflows.count == 1)
        #expect(store.workflows.first?.id == "module.video.default")
    }

    @Test func synchronizeDefaultWorkflowsPreservesEditedDefaultWorkflow() throws {
        let runtime = ModuleRuntime()
        runtime.register(module: TestWorkflowModule(
            id: "video",
            name: "Video Frame Extraction",
            summary: "Find strong still frames from a video."
        ))
        runtime.setModuleEnabled("video", isEnabled: true)

        let store = WorkflowStore()
        store.synchronizeDefaultWorkflows(with: runtime)

        store.save(
            WorkflowRecord(
                id: "module.video.default",
                title: "Video Storyboard",
                summary: "Generate a custom storyboard from a clip.",
                source: .moduleDefault(moduleID: "video"),
                tags: [
                    WorkflowTagRecord(id: "storyboard", name: "Storyboard"),
                ],
                nodes: [
                    WorkflowNode(id: "video.root", moduleID: "video", title: "Edited Extractor"),
                ],
                connections: []
            )
        )

        store.synchronizeDefaultWorkflows(with: runtime)

        let workflow = try #require(store.workflows.first)
        #expect(workflow.id == "module.video.default")
        #expect(workflow.title == "Video Storyboard")
        #expect(workflow.summary == "Generate a custom storyboard from a clip.")
        #expect(workflow.tags == [
            WorkflowTagRecord(id: "storyboard", name: "Storyboard"),
        ])
        #expect(workflow.nodes == [
            WorkflowNode(id: "video.root", moduleID: "video", title: "Edited Extractor"),
        ])
    }

    @Test func synchronizeDefaultWorkflowsRemovesStaleDefaultWorkflows() {
        let initialRuntime = ModuleRuntime()
        initialRuntime.register(module: TestWorkflowModule(
            id: "audio",
            name: "Audio Extraction",
            summary: "Extract an audio track from a source clip."
        ))
        initialRuntime.register(module: TestWorkflowModule(
            id: "video",
            name: "Video Frame Extraction",
            summary: "Find strong still frames from a video."
        ))
        initialRuntime.setModuleEnabled("audio", isEnabled: true)
        initialRuntime.setModuleEnabled("video", isEnabled: true)

        let updatedRuntime = ModuleRuntime()
        updatedRuntime.register(module: TestWorkflowModule(
            id: "video",
            name: "Video Frame Extraction",
            summary: "Find strong still frames from a video."
        ))
        updatedRuntime.setModuleEnabled("video", isEnabled: true)

        let store = WorkflowStore()
        store.synchronizeDefaultWorkflows(with: initialRuntime)
        store.synchronizeDefaultWorkflows(with: updatedRuntime)

        #expect(store.workflows.map(\.id) == ["module.video.default"])
    }

    @Test func disabledModuleWorkflowRemainsVisibleButUnavailable() throws {
        let runtime = ModuleRuntime()
        runtime.register(module: TestWorkflowModule(
            id: "video",
            name: "Video Frame Extraction",
            summary: "Find strong still frames from a video."
        ))
        runtime.setModuleEnabled("video", isEnabled: true)

        let store = WorkflowStore()
        store.synchronizeDefaultWorkflows(with: runtime)

        runtime.setModuleEnabled("video", isEnabled: false)
        store.synchronizeDefaultWorkflows(with: runtime)

        #expect(store.workflows.count == 1)
        let workflow = try #require(store.workflows.first)
        #expect(store.availability(for: workflow, with: runtime) == .unavailable(requiredModuleIDs: ["video"]))
    }

    @Test func availabilityIsDerivedFromCurrentRuntime() throws {
        let runtime = ModuleRuntime()
        runtime.register(module: TestWorkflowModule(
            id: "video-frame-extraction",
            name: "Video Frame Extraction",
            summary: "Find strong still frames from a video."
        ))
        runtime.setModuleEnabled("video-frame-extraction", isEnabled: true)

        let store = WorkflowStore()
        store.save(
            WorkflowRecord(
                id: "workflow.video-storyboard",
                title: "Video Storyboard",
                summary: "Generate a storyboard from a clip.",
                source: .userAuthored,
                tags: [
                    WorkflowTagRecord(id: "video", name: "Video"),
                ],
                nodes: [
                    WorkflowNode(id: "video-node", moduleID: "video-frame-extraction", title: "Frame Extractor"),
                ],
                connections: []
            )
        )

        let workflow = try #require(store.workflows.first)
        #expect(store.availability(for: workflow, with: runtime) == .available)

        runtime.setModuleEnabled("video-frame-extraction", isEnabled: false)

        #expect(store.availability(for: workflow, with: runtime) == .unavailable(requiredModuleIDs: ["video-frame-extraction"]))
    }

    @Test func libraryQueryFiltersAndGroupsByTag() {
        let store = WorkflowStore()
        store.save(
            WorkflowRecord(
                id: "workflow.image-contact-sheet",
                title: "Image Contact Sheet",
                summary: "Build a review sheet from selected frames.",
                source: .userAuthored,
                tags: [
                    WorkflowTagRecord(id: "images", name: "Images"),
                    WorkflowTagRecord(id: "review", name: "Review"),
                ],
                nodes: [
                    WorkflowNode(id: "video-node", moduleID: "video-frame-extraction", title: "Frame Extractor"),
                ],
                connections: []
            )
        )
        store.save(
            WorkflowRecord(
                id: "workflow.video-storyboard",
                title: "Video Storyboard",
                summary: "Generate a storyboard from a clip.",
                source: .userAuthored,
                tags: [
                    WorkflowTagRecord(id: "video", name: "Video"),
                    WorkflowTagRecord(id: "review", name: "Review"),
                ],
                nodes: [
                    WorkflowNode(id: "video-node", moduleID: "video-frame-extraction", title: "Frame Extractor"),
                ],
                connections: []
            )
        )
        store.save(
            WorkflowRecord(
                id: "workflow.audio-archive",
                title: "Audio Archive",
                summary: "Store an extracted audio track.",
                source: .userAuthored,
                tags: [
                    WorkflowTagRecord(id: "audio", name: "Audio"),
                ],
                nodes: [
                    WorkflowNode(id: "audio-node", moduleID: "audio-extraction", title: "Audio Extractor"),
                ],
                connections: []
            )
        )

        let library = store.library(filteringByTagID: "review")

        #expect(library.workflows.map(\.id) == [
            "workflow.image-contact-sheet",
            "workflow.video-storyboard",
        ])
        #expect(library.sections.map(\.title) == ["Review"])
        #expect(library.sections.first?.workflows.map(\.id) == [
            "workflow.image-contact-sheet",
            "workflow.video-storyboard",
        ])
    }
}

private final class TestWorkflowModule: ToolModule {
    let descriptor: ModuleDescriptor

    init(id: String, name: String, summary: String) {
        descriptor = ModuleDescriptor(
            id: id,
            name: name,
            summary: summary,
            capabilities: [.workspace]
        )
    }

    func load() {}

    func unload() {}

    func makeWorkspaceView(session: ToolSession) -> AnyView {
        AnyView(EmptyView())
    }
}

import Testing
@testable import Flexora

struct WorkflowTaskViewLogicTests {
    @Test func emptyWorkflowUsesEmptyPresentation() {
        let workflow = WorkflowRecord(
            id: "workflow.empty",
            title: "Empty",
            summary: "",
            source: .userAuthored,
            tags: [],
            nodes: [],
            connections: []
        )

        let presentation = WorkflowTaskPresentation.resolve(
            workflow: workflow,
            availability: .available,
            activeSessionModuleID: nil,
            runtimeHasModule: { _ in false }
        )

        #expect(presentation == .empty)
    }

    @Test func singleModuleWorkflowUsesWorkspacePresentationWhenSessionMatches() {
        let workflow = WorkflowRecord(
            id: "workflow.video",
            title: "Video",
            summary: "",
            source: .userAuthored,
            tags: [],
            nodes: [
                WorkflowNode(id: "video-node", moduleID: "video", title: "Extract Frames"),
            ],
            connections: []
        )

        let presentation = WorkflowTaskPresentation.resolve(
            workflow: workflow,
            availability: .available,
            activeSessionModuleID: "video",
            runtimeHasModule: { $0 == "video" }
        )

        #expect(presentation == .workspace(moduleID: "video"))
    }

    @Test func multiModuleWorkflowUsesSummaryPresentation() {
        let workflow = WorkflowRecord(
            id: "workflow.storyboard",
            title: "Storyboard",
            summary: "",
            source: .userAuthored,
            tags: [],
            nodes: [
                WorkflowNode(id: "video-node", moduleID: "video", title: "Extract Frames"),
                WorkflowNode(id: "image-node", moduleID: "images", title: "Build Contact Sheet"),
            ],
            connections: []
        )

        let presentation = WorkflowTaskPresentation.resolve(
            workflow: workflow,
            availability: .available,
            activeSessionModuleID: nil,
            runtimeHasModule: { _ in false }
        )

        #expect(presentation == .summary)
    }

    @Test func sequentialConnectionsReplaceOutgoingDestinationForSourceNode() {
        let nodes = [
            WorkflowNode(id: "step-a", moduleID: "video", title: "A"),
            WorkflowNode(id: "step-b", moduleID: "images", title: "B"),
            WorkflowNode(id: "step-c", moduleID: "audio", title: "C"),
        ]
        let connections = [
            WorkflowConnection(id: "step-a->step-b", sourceNodeID: "step-a", destinationNodeID: "step-b"),
            WorkflowConnection(id: "step-b->step-c", sourceNodeID: "step-b", destinationNodeID: "step-c"),
        ]

        let updated = WorkflowSequentialConnections.settingDestinationNodeID(
            "step-c",
            for: "step-a",
            nodes: nodes,
            existingConnections: connections
        )

        #expect(updated == [
            WorkflowConnection(id: "step-a->step-c", sourceNodeID: "step-a", destinationNodeID: "step-c"),
            WorkflowConnection(id: "step-b->step-c", sourceNodeID: "step-b", destinationNodeID: "step-c"),
        ])
    }

    @Test func sequentialConnectionsAutoConnectInCurrentOrder() {
        let nodes = [
            WorkflowNode(id: "step-a", moduleID: "video", title: "A"),
            WorkflowNode(id: "step-b", moduleID: "images", title: "B"),
            WorkflowNode(id: "step-c", moduleID: "audio", title: "C"),
        ]

        let connections = WorkflowSequentialConnections.connectInOrder(nodes: nodes)

        #expect(connections == [
            WorkflowConnection(id: "step-a->step-b", sourceNodeID: "step-a", destinationNodeID: "step-b"),
            WorkflowConnection(id: "step-b->step-c", sourceNodeID: "step-b", destinationNodeID: "step-c"),
        ])
    }
}

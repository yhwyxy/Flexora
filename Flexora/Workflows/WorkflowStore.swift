import Combine

@MainActor
public final class WorkflowStore: ObservableObject {
    @Published public private(set) var workflows: [WorkflowRecord]

    public init(workflows: [WorkflowRecord] = []) {
        self.workflows = Self.sorted(workflows)
    }

    public func save(_ workflow: WorkflowRecord) {
        upsert(workflow)
    }

    public func synchronizeDefaultWorkflows(with runtime: ModuleRuntime) {
        let moduleDescriptors = runtime.allModules
        let registeredModuleIDs = Set(moduleDescriptors.map(\.id))

        var reconciledWorkflows = workflows.filter { workflow in
            switch workflow.source {
            case .moduleDefault(let moduleID):
                return registeredModuleIDs.contains(moduleID)
            case .userAuthored:
                return true
            }
        }

        for descriptor in moduleDescriptors {
            let workflowID = "module.\(descriptor.id).default"

            if reconciledWorkflows.contains(where: { $0.id == workflowID }) == false {
                reconciledWorkflows.append(defaultWorkflow(for: descriptor))
            }
        }

        workflows = Self.sorted(reconciledWorkflows)
    }

    public func library(filteringByTagID tagID: String? = nil) -> WorkflowLibrary {
        let filteredWorkflows = Self.sorted(workflows.filter { workflow in
            guard let tagID else {
                return true
            }

            return workflow.tags.contains { $0.id == tagID }
        })

        guard let tagID else {
            return WorkflowLibrary(
                workflows: filteredWorkflows,
                sections: groupedSections(for: filteredWorkflows)
            )
        }

        let tag = filteredWorkflows
            .flatMap(\.tags)
            .first { $0.id == tagID }

        let sections: [WorkflowLibrary.Section]
        if filteredWorkflows.isEmpty {
            sections = []
        } else {
            sections = [WorkflowLibrary.Section(tag: tag, workflows: filteredWorkflows)]
        }

        return WorkflowLibrary(workflows: filteredWorkflows, sections: sections)
    }

    public func availability(for workflow: WorkflowRecord, with runtime: ModuleRuntime) -> WorkflowAvailability {
        let requiredModuleIDs = Array(Set(workflow.nodes.map(\.moduleID))).sorted()
        let unavailableModuleIDs = requiredModuleIDs.filter { !runtime.isModuleEnabled($0) }

        guard unavailableModuleIDs.isEmpty else {
            return .unavailable(requiredModuleIDs: unavailableModuleIDs)
        }

        return .available
    }

    private func upsert(_ workflow: WorkflowRecord) {
        if let index = workflows.firstIndex(where: { $0.id == workflow.id }) {
            workflows[index] = workflow
        } else {
            workflows.append(workflow)
        }

        workflows = Self.sorted(workflows)
    }

    private func defaultWorkflow(for descriptor: ModuleDescriptor) -> WorkflowRecord {
        WorkflowRecord(
            id: "module.\(descriptor.id).default",
            title: descriptor.name,
            summary: descriptor.summary,
            source: .moduleDefault(moduleID: descriptor.id),
            tags: [],
            nodes: [
                WorkflowNode(
                    id: "\(descriptor.id).root",
                    moduleID: descriptor.id,
                    title: descriptor.name
                ),
            ],
            connections: []
        )
    }

    private func groupedSections(for workflows: [WorkflowRecord]) -> [WorkflowLibrary.Section] {
        var taggedSections: [String: (tag: WorkflowTagRecord, workflows: [WorkflowRecord])] = [:]
        var untaggedWorkflows: [WorkflowRecord] = []

        for workflow in workflows {
            guard workflow.tags.isEmpty == false else {
                untaggedWorkflows.append(workflow)
                continue
            }

            for tag in workflow.tags {
                taggedSections[tag.id, default: (tag, [])].workflows.append(workflow)
            }
        }

        var sections = taggedSections.values
            .map { value in
                WorkflowLibrary.Section(
                    tag: value.tag,
                    workflows: Self.sorted(value.workflows)
                )
            }
            .sorted { $0.title < $1.title }

        if untaggedWorkflows.isEmpty == false {
            sections.append(
                WorkflowLibrary.Section(
                    tag: nil,
                    workflows: Self.sorted(untaggedWorkflows)
                )
            )
        }

        return sections
    }

    private static func sorted(_ workflows: [WorkflowRecord]) -> [WorkflowRecord] {
        workflows.sorted {
            if $0.title == $1.title {
                return $0.id < $1.id
            }

            return $0.title < $1.title
        }
    }
}

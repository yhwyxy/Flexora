import SwiftUI

enum WorkflowTaskPresentation: Equatable {
    case empty
    case workspace(moduleID: String)
    case unavailable(requiredModuleIDs: [String])
    case inactiveWorkspace(moduleID: String)
    case summary

    static func resolve(
        workflow: WorkflowRecord,
        availability: WorkflowAvailability,
        activeSessionModuleID: String?,
        runtimeHasModule: (String) -> Bool
    ) -> Self {
        let moduleIDs = Array(Set(workflow.nodes.map(\.moduleID))).sorted()

        guard moduleIDs.isEmpty == false else {
            return .empty
        }

        guard moduleIDs.count == 1, let moduleID = moduleIDs.first else {
            return .summary
        }

        switch availability {
        case .available:
            guard activeSessionModuleID == moduleID, runtimeHasModule(moduleID) else {
                return .inactiveWorkspace(moduleID: moduleID)
            }

            return .workspace(moduleID: moduleID)
        case .unavailable(let requiredModuleIDs):
            return .unavailable(requiredModuleIDs: requiredModuleIDs)
        }
    }
}

struct WorkflowTaskView: View {
    @ObservedObject var model: AppModel
    let workflowID: String

    var body: some View {
        Group {
            if let workflow {
                switch taskPresentation(for: workflow) {
                case .empty:
                    emptyWorkflowView(for: workflow)
                case .workspace(let moduleID):
                    workspaceHost(for: workflow, moduleID: moduleID)
                case .unavailable(let requiredModuleIDs):
                    unavailableView(for: workflow, requiredModuleIDs: requiredModuleIDs)
                case .inactiveWorkspace(let moduleID):
                    inactiveWorkspaceView(for: workflow, moduleID: moduleID)
                case .summary:
                    summaryView(for: workflow)
                }
            } else {
                ContentUnavailableView(
                    "Workflow Missing",
                    systemImage: "exclamationmark.triangle",
                    description: Text("The requested workflow could not be found in the current library.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(workflow?.title ?? "Task")
    }

    private var workflow: WorkflowRecord? {
        model.workflowStore.workflows.first(where: { $0.id == workflowID })
    }

    private var moduleDescriptorsByID: [String: ModuleDescriptor] {
        Dictionary(uniqueKeysWithValues: model.runtime.allModules.map { ($0.id, $0) })
    }

    private func taskPresentation(for workflow: WorkflowRecord) -> TaskPresentation {
        WorkflowTaskPresentation.resolve(
            workflow: workflow,
            availability: model.workflowStore.availability(for: workflow, with: model.runtime),
            activeSessionModuleID: model.activeSession?.moduleID,
            runtimeHasModule: { model.runtime.module(withID: $0) != nil }
        )
    }

    private func emptyWorkflowView(for workflow: WorkflowRecord) -> some View {
        VStack(spacing: 24) {
            workflowHeader(
                title: workflow.title,
                summary: workflow.summary,
                badgeTitle: "Empty Draft",
                badgeTint: .yellow
            )

            ContentUnavailableView(
                "No Steps Yet",
                systemImage: "square.dashed",
                description: Text("This workflow is saved as an empty draft. Add at least one module in the editor before opening it as a task.")
            )

            Button("Edit Workflow") {
                model.editWorkflow(withID: workflow.id)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(24)
    }

    private func workspaceHost(for workflow: WorkflowRecord, moduleID: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            workflowHeader(
                title: workflow.title,
                summary: workflow.summary,
                badgeTitle: "Single Module",
                badgeTint: .green
            )
            Divider()

            if
                let session = model.activeSession,
                session.moduleID == moduleID,
                let module = model.runtime.module(withID: moduleID)
            {
                module.makeWorkspaceView(session: session)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "Workspace Unavailable",
                    systemImage: "square.slash",
                    description: Text("The workflow resolves to \(moduleName(for: moduleID)), but its workspace is not available.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func unavailableView(for workflow: WorkflowRecord, requiredModuleIDs: [String]) -> some View {
        let names = requiredModuleIDs.map(moduleName(for:)).joined(separator: ", ")

        return VStack(spacing: 24) {
            workflowHeader(
                title: workflow.title,
                summary: workflow.summary,
                badgeTitle: "Unavailable",
                badgeTint: .orange
            )

            ContentUnavailableView(
                "Workflow Unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text("Enable the required modules before running this workflow: \(names).")
            )

            Button("Edit Workflow") {
                model.editWorkflow(withID: workflow.id)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(24)
    }

    private func inactiveWorkspaceView(for workflow: WorkflowRecord, moduleID: String) -> some View {
        VStack(spacing: 24) {
            workflowHeader(
                title: workflow.title,
                summary: workflow.summary,
                badgeTitle: "Needs Refresh",
                badgeTint: .orange
            )

            ContentUnavailableView(
                "Workspace Not Ready",
                systemImage: "square.slash",
                description: Text("This workflow points to \(moduleName(for: moduleID)), but its workspace is not active right now. Reopen it after the module becomes available, or edit the workflow.")
            )

            Button("Edit Workflow") {
                model.editWorkflow(withID: workflow.id)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(24)
    }

    private func summaryView(for workflow: WorkflowRecord) -> some View {
        let moduleIDs = uniqueModuleIDs(in: workflow)

        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                workflowHeader(
                    title: workflow.title,
                    summary: workflow.summary,
                    badgeTitle: "Summary Only",
                    badgeTint: .blue
                )

                Text("Multi-module execution is not implemented in V1. Review the graph below and use the editor to repair or refine the workflow.")
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    statCard(title: "Modules", value: "\(moduleIDs.count)", systemImage: "square.stack.3d.up")
                    statCard(title: "Nodes", value: "\(workflow.nodes.count)", systemImage: "square.on.square")
                    statCard(title: "Connections", value: "\(workflow.connections.count)", systemImage: "arrow.triangle.branch")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Execution Outline")
                        .font(.title3.weight(.semibold))

                    ForEach(workflow.nodes) { node in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(node.title)
                                .font(.headline)

                            Text(moduleName(for: node.moduleID))
                                .foregroundStyle(.secondary)

                            let downstreamNodes = workflow.connections
                                .filter { $0.sourceNodeID == node.id }
                                .compactMap { connection in
                                    workflow.nodes.first(where: { $0.id == connection.destinationNodeID })?.title
                                }

                            Text(downstreamNodes.isEmpty ? "No downstream connection recorded." : "Feeds: \(downstreamNodes.joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(nsColor: .windowBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                }

                Button("Edit Workflow") {
                    model.editWorkflow(withID: workflow.id)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
        }
    }

    private func workflowHeader(title: String, summary: String, badgeTitle: String, badgeTint: Color) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.largeTitle.bold())

                Text(summary.isEmpty ? "No summary provided." : summary)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(badgeTitle)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(badgeTint.opacity(0.14), in: Capsule())
                .foregroundStyle(badgeTint)
        }
        .padding(24)
    }

    private func statCard(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func uniqueModuleIDs(in workflow: WorkflowRecord) -> [String] {
        Array(Set(workflow.nodes.map(\.moduleID))).sorted()
    }

    private func moduleName(for moduleID: String) -> String {
        moduleDescriptorsByID[moduleID]?.name ?? moduleID
    }

    private typealias TaskPresentation = WorkflowTaskPresentation
}

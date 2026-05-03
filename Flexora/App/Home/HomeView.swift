import SwiftUI

struct HomeView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        let library = model.workflowStore.library()

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if library.workflows.isEmpty {
                    ContentUnavailableView(
                        "No Workflows Yet",
                        systemImage: "square.stack.3d.up.slash",
                        description: Text("Register a module or add a workflow to populate the Home library.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    ForEach(Array(library.sections.enumerated()), id: \.offset) { _, section in
                        workflowSection(section)
                    }
                }
            }
            .padding(24)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workflow Library")
                .font(.largeTitle.bold())

            Text("Open a ready workflow or jump into its editor. Availability reflects which modules are enabled right now.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func workflowSection(_ section: WorkflowLibrary.Section) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.title3.weight(.semibold))

            ForEach(section.workflows) { workflow in
                WorkflowCardView(
                    workflow: workflow,
                    sourceDescription: sourceDescription(for: workflow),
                    availabilityDescription: availabilityDescription(for: workflow),
                    availabilityTint: availabilityTint(for: workflow),
                    isAvailable: isAvailable(workflow),
                    onOpen: { model.openWorkflow(withID: workflow.id) },
                    onEdit: { model.editWorkflow(withID: workflow.id) }
                )
            }
        }
    }

    private func sourceDescription(for workflow: WorkflowRecord) -> String {
        switch workflow.source {
        case .moduleDefault(let moduleID):
            if let module = model.runtime.allModules.first(where: { $0.id == moduleID }) {
                return "Module default: \(module.name)"
            }

            return "Module default: \(moduleID)"
        case .userAuthored:
            return "User-authored workflow"
        }
    }

    private func availabilityDescription(for workflow: WorkflowRecord) -> String {
        switch model.workflowStore.availability(for: workflow, with: model.runtime) {
        case .available:
            return "Ready to open"
        case .unavailable(let requiredModuleIDs):
            let moduleList = requiredModuleIDs.joined(separator: ", ")
            return "Unavailable until enabled: \(moduleList)"
        }
    }

    private func availabilityTint(for workflow: WorkflowRecord) -> Color {
        switch model.workflowStore.availability(for: workflow, with: model.runtime) {
        case .available:
            return .green
        case .unavailable:
            return .orange
        }
    }

    private func isAvailable(_ workflow: WorkflowRecord) -> Bool {
        switch model.workflowStore.availability(for: workflow, with: model.runtime) {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }
}

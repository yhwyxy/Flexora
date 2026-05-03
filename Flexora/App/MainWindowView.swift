import SwiftUI

struct MainWindowView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationSplitView {
            AppSidebarView(model: model)
        } detail: {
            switch model.route {
            case .home:
                HomeView(model: model)
            case .workshop:
                shellPlaceholder(
                    title: "Workshop",
                    systemImage: "hammer",
                    description: "Workshop tools land here in a later task."
                )
            case .modules:
                ModuleLibraryView(model: model)
            case let .task(workflowID):
                taskView(for: workflowID)
            case let .workflowEditor(workflowID):
                shellPlaceholder(
                    title: "Workflow Editor",
                    systemImage: "square.and.pencil",
                    description: "Editing \(workflowID) arrives in a later task."
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func taskView(for workflowID: String) -> some View {
        if let moduleID = taskWorkspaceModuleID(for: workflowID) {
            workspaceView(for: moduleID)
        } else {
            shellPlaceholder(
                title: "Task",
                systemImage: "checklist",
                description: "Workflow \(workflowID) does not currently resolve to a single active module workspace."
            )
        }
    }

    func taskWorkspaceModuleID(for workflowID: String) -> String? {
        guard
            let workflow = model.workflowStore.workflows.first(where: { $0.id == workflowID }),
            let session = model.activeSession
        else {
            return nil
        }

        let moduleIDs = Array(Set(workflow.nodes.map(\.moduleID))).sorted()
        guard moduleIDs.count == 1, let moduleID = moduleIDs.first else {
            return nil
        }

        guard session.moduleID == moduleID, model.runtime.module(withID: moduleID) != nil else {
            return nil
        }

        return moduleID
    }

    @ViewBuilder
    private func workspaceView(for moduleID: String) -> some View {
        if
            let session = model.activeSession,
            session.moduleID == moduleID,
            let module = model.runtime.module(withID: moduleID)
        {
            module.makeWorkspaceView(session: session)
        } else {
            ContentUnavailableView("Module Unavailable", systemImage: "square.slash")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func shellPlaceholder(title: String, systemImage: String, description: String) -> some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(description))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

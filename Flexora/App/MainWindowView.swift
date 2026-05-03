import SwiftUI

struct MainWindowView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationSplitView {
            List {
                Button("Home") {
                    model.route = .home
                }
                .buttonStyle(.plain)

                Button("Workshop") {
                    model.route = .workshop
                }
                .buttonStyle(.plain)

                Button("Modules") {
                    model.route = .modules
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Flexora")
        } detail: {
            switch model.route {
            case .home:
                placeholderView(
                    title: "Home",
                    systemImage: "house",
                    description: "Home workflow navigation is not implemented yet."
                )
            case .workshop:
                placeholderView(
                    title: "Workshop",
                    systemImage: "hammer",
                    description: "Workshop workflow navigation is not implemented yet."
                )
            case .modules:
                ModuleSelectionView(model: model)
            case let .task(workflowID):
                taskView(for: workflowID)
            case let .workflowEditor(workflowID):
                placeholderView(
                    title: "Workflow Editor",
                    systemImage: "square.and.pencil",
                    description: "Editing \(workflowID) is not implemented yet."
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func taskView(for workflowID: String) -> some View {
        if let moduleID = model.activeSession?.moduleID {
            workspaceView(for: moduleID)
        } else {
            placeholderView(
                title: "Workflow Task",
                systemImage: "square.stack.3d.up",
                description: "Workflow \(workflowID) does not currently have an active module workspace."
            )
        }
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
        }
    }

    private func placeholderView(title: String, systemImage: String, description: String) -> some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(description))
    }
}

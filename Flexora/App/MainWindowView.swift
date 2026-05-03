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
                shellPlaceholder(
                    title: "Task",
                    systemImage: "checklist",
                    description: "Workflow \(workflowID) will open in the task surface in a later task."
                )
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

    private func shellPlaceholder(title: String, systemImage: String, description: String) -> some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(description))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

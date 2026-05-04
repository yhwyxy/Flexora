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
                WorkflowWorkshopView(model: model)
            case .modules:
                ModuleLibraryView(model: model)
            case let .task(workflowID):
                WorkflowTaskView(model: model, workflowID: workflowID)
            case let .workflowEditor(workflowID):
                WorkflowWorkshopView(model: model, workflowID: workflowID)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

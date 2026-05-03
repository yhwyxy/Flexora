import SwiftUI

struct MainWindowView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationSplitView {
            List {
                Button("Choose Modules") {
                    model.route = .moduleChooser
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Flexora")
        } detail: {
            switch model.route {
            case .moduleChooser:
                ModuleSelectionView(model: model)
            case let .workspace(moduleID):
                workspaceView(for: moduleID)
            }
        }
        .navigationSplitViewStyle(.balanced)
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
}

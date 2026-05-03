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
                model.workspaceView(for: moduleID)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

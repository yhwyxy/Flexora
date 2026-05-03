import SwiftUI

struct AppSidebarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List(selection: selection) {
            Section("Workspace") {
                ForEach(SidebarDestination.allCases) { destination in
                    Label(destination.title, systemImage: destination.systemImage)
                        .tag(destination)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Flexora")
    }

    private var selection: Binding<SidebarDestination?> {
        Binding(
            get: {
                switch model.route {
                case .home, .task, .workflowEditor:
                    return .home
                case .workshop:
                    return .workshop
                case .modules:
                    return .modules
                }
            },
            set: { destination in
                guard let destination else {
                    return
                }

                switch destination {
                case .home:
                    model.showHome()
                case .workshop:
                    model.showWorkshop()
                case .modules:
                    model.showModules()
                }
            }
        )
    }
}

private enum SidebarDestination: String, CaseIterable, Identifiable {
    case home
    case workshop
    case modules

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .workshop:
            return "Workshop"
        case .modules:
            return "Modules"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .workshop:
            return "hammer"
        case .modules:
            return "square.stack.3d.up"
        }
    }
}

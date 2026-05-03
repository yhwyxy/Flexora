import SwiftUI

struct AppSidebarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List {
            Section("Workspace") {
                ForEach(AppSidebarDestination.allCases) { destination in
                    Button(action: {
                        navigate(to: destination)
                    }) {
                        sidebarRow(for: destination)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Flexora")
    }

    var activeDestination: AppSidebarDestination? {
        guard let route = model.route.topLevelRoute else {
            return nil
        }

        switch route {
        case .home:
            return .home
        case .workshop:
            return .workshop
        case .modules:
            return .modules
        }
    }

    @ViewBuilder
    private func sidebarRow(for destination: AppSidebarDestination) -> some View {
        Label(destination.title, systemImage: destination.systemImage)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(activeDestination == destination ? Color.accentColor.opacity(0.18) : Color.clear)
            )
            .contentShape(Rectangle())
    }

    private func navigate(to destination: AppSidebarDestination) {
        switch destination {
        case .home:
            model.showHome()
        case .workshop:
            model.showWorkshop()
        case .modules:
            model.showModules()
        }
    }
}

enum AppSidebarDestination: String, CaseIterable, Identifiable {
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

import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TabView {
            ModuleManagementView(model: model)
                .tabItem {
                    Label("Modules", systemImage: "square.stack.3d.up")
                }
        }
        .frame(minWidth: 480, minHeight: 320)
        .padding(20)
    }
}

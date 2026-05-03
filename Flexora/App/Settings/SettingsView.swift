import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Module Management Moved", systemImage: "arrow.right.square")
                .font(.title2.weight(.semibold))

            Text("Module enablement now lives in the Modules page in the main window. This Settings screen is temporary until the rest of the preferences surface is defined.")
                .foregroundStyle(.secondary)

            Button("Open Modules") {
                model.showModules()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(minWidth: 420, minHeight: 180, alignment: .topLeading)
        .padding(20)
    }
}

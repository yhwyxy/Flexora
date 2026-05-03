import SwiftUI

struct ModuleSelectionView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a Module")
                .font(.largeTitle.bold())

            ForEach(model.runtime.availableModules, id: \.id) { module in
                Button(module.name) {
                    model.openModule(withID: module.id)
                }
                .buttonStyle(.borderedProminent)
            }

            if model.runtime.availableModules.isEmpty {
                ContentUnavailableView(
                    "No Modules Enabled",
                    systemImage: "square.stack.3d.up.slash",
                    description: Text("Enable a module in Settings to make it available here.")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

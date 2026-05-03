import SwiftUI

struct ModuleLibraryView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if model.runtime.allModules.isEmpty {
                    ContentUnavailableView(
                        "No Modules Registered",
                        systemImage: "square.stack.3d.up.slash",
                        description: Text("Register a module to make it available in the library.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(model.runtime.allModules, id: \.id) { module in
                            ModuleCardView(
                                module: module,
                                isEnabled: Binding(
                                    get: { model.runtime.isModuleEnabled(module.id) },
                                    set: { model.setModuleEnabled(module.id, isEnabled: $0) }
                                )
                            )
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Module Library")
                .font(.largeTitle.bold())

            Text("Enable modules here to make their workflows available on Home.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

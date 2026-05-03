import SwiftUI

struct ModuleManagementView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Modules")
                .font(.title.bold())

            List(model.runtime.allModules, id: \.id) { module in
                Toggle(
                    isOn: Binding(
                        get: { model.runtime.isModuleEnabled(module.id) },
                        set: { model.setModuleEnabled(module.id, isEnabled: $0) }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(module.name)
                        Text(module.id)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(minHeight: 220)
        }
    }
}

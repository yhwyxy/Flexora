import SwiftUI

struct ModuleCardView: View {
    let module: ModuleDescriptor
    @Binding var isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(module.name)
                        .font(.title3.weight(.semibold))

                    Text(module.summary.isEmpty ? "No summary provided yet." : module.summary)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Toggle("Enabled", isOn: $isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            HStack(spacing: 8) {
                badge(title: module.id, systemImage: "number")

                if module.capabilities.isEmpty {
                    badge(title: "No capabilities", systemImage: "square.dashed")
                } else {
                    ForEach(module.capabilities.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { capability in
                        badge(title: capabilityLabel(capability), systemImage: "sparkles")
                    }
                }
            }

            Text(isEnabled ? "Enabled for workflows and runtime activation." : "Disabled until you turn this module on.")
                .font(.caption)
                .foregroundStyle(isEnabled ? .green : .secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.quaternary.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }

    private func capabilityLabel(_ capability: ModuleCapability) -> String {
        switch capability {
        case .workspace:
            return "Workspace"
        }
    }

    private func badge(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(.quaternary.opacity(0.8))
            )
    }
}

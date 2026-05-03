import SwiftUI

struct WorkflowCardView: View {
    let workflow: WorkflowRecord
    let sourceDescription: String
    let availabilityDescription: String
    let availabilityTint: Color
    let isAvailable: Bool
    let onOpen: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(workflow.title)
                    .font(.title3.weight(.semibold))

                Text(workflow.summary.isEmpty ? "No summary provided yet." : workflow.summary)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                MetadataChip(title: sourceDescription, systemImage: "shippingbox")
                MetadataChip(title: availabilityDescription, systemImage: "bolt.circle", accent: availabilityTint)
            }

            if workflow.tags.isEmpty {
                MetadataChip(title: "No tags", systemImage: "tag")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), alignment: .leading)], alignment: .leading, spacing: 8) {
                    ForEach(workflow.tags) { tag in
                        MetadataChip(title: tag.name, systemImage: "tag")
                    }
                }
            }

            HStack {
                Button("Open", action: onOpen)
                    .buttonStyle(.borderedProminent)
                    .disabled(isAvailable == false)

                Button("Edit", action: onEdit)
                    .buttonStyle(.bordered)
            }
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
}

private struct MetadataChip: View {
    let title: String
    let systemImage: String
    var accent: Color = .secondary

    var body: some View {
        Label {
            Text(title)
                .lineLimit(2)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(accent.opacity(0.12))
        )
    }
}

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct FileDropZone: View {
    let title: String
    var onDropURLs: ([URL]) -> Void = { _ in }
    var onActivate: () -> Void = {}

    @State private var isTargeted = false

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                isTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                style: StrokeStyle(lineWidth: 2, dash: [10])
            )
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.secondary.opacity(isTargeted ? 0.12 : 0.06))
            )
            .frame(maxWidth: .infinity, minHeight: 140)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.headline)
                    Text("Supported formats: .mov, .mp4")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop(providers:))
            .onTapGesture(perform: onActivate)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let supportedProviderFound = providers.contains { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard supportedProviderFound else {
            return false
        }

        for provider in providers {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                guard let url = Self.decodeFileURL(from: data) else {
                    return
                }

                DispatchQueue.main.async {
                    onDropURLs([url])
                }
            }
        }

        return true
    }

    static func decodeFileURL(from data: Data?) -> URL? {
        guard let data else {
            return nil
        }

        return URL(dataRepresentation: data, relativeTo: nil)
    }
}

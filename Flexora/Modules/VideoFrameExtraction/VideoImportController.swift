import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

final class VideoImportController: ObservableObject {
    private let supportedExtensions: Set<String> = ["mov", "mp4"]

    @Published var importedVideoURL: URL?

    init(importedVideoURL: URL? = nil) {
        self.importedVideoURL = importedVideoURL
    }

    func isSupportedVideoURL(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    func importVideo(_ url: URL) {
        guard isSupportedVideoURL(url) else { return }
        importedVideoURL = url
    }

    func promptForVideoImport() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.movie, .mpeg4Movie]

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        importVideo(url)
    }
}

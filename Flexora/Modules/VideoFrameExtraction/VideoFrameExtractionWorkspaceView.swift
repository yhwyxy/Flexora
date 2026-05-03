import SwiftUI

struct VideoFrameExtractionWorkspaceView: View {
    @StateObject private var importController = VideoImportController()
    @StateObject private var browserModel = ThumbnailBrowserViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Button("Import Video") {
                    importController.promptForVideoImport()
                }

                Spacer()

                Button("Export") {}
                    .disabled(browserModel.exportSelection.isEmpty)
            }

            FileDropZone(title: "Drop a video here") { urls in
                guard let firstSupportedURL = urls.first(where: importController.isSupportedVideoURL(_:)) else {
                    return
                }

                importController.importVideo(firstSupportedURL)
            }

            if let importedVideoURL = importController.importedVideoURL {
                Text(importedVideoURL.lastPathComponent)
                    .font(.headline)
            } else {
                ContentUnavailableView("No Video Loaded", systemImage: "film")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

import SwiftUI

final class VideoFrameExtractionModule: ToolModule {
    let descriptor = ModuleDescriptor(
        id: "video-frame-extraction",
        name: "Video Frame Extraction",
        capabilities: [.workspace]
    )

    func load() {}

    func unload() {}

    func makeWorkspaceView(session: ToolSession) -> AnyView {
        let importController: VideoImportController
        let browserModel: ThumbnailBrowserViewModel

        if ProcessInfo.processInfo.arguments.contains("-flexora-ui-sample-candidates") {
            importController = VideoImportController(
                importedVideoURL: URL(fileURLWithPath: "/tmp/sample-wallpaper.mov")
            )
            browserModel = ThumbnailBrowserViewModel()
            browserModel.loadCandidates(sampleCandidates)
            if let first = sampleCandidates.first {
                browserModel.toggleSelection(for: first)
            }
        } else {
            importController = VideoImportController()
            browserModel = ThumbnailBrowserViewModel()
        }

        return AnyView(
            VideoFrameExtractionWorkspaceView(
                session: session,
                importController: importController,
                browserModel: browserModel
            )
        )
    }
}

private let sampleCandidates = [
    VideoFrameCandidate(time: 0.0, score: 0.34),
    VideoFrameCandidate(time: 4.0, score: 0.62),
    VideoFrameCandidate(time: 8.0, score: 0.91),
]

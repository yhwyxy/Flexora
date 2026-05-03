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
        AnyView(VideoFrameExtractionWorkspaceView())
    }
}

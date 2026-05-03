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
        AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("Video Frame Extraction")
                    .font(.largeTitle.bold())
                Text("Module session: \(session.moduleID)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Video import and extraction flows will be added in a later task.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        )
    }
}

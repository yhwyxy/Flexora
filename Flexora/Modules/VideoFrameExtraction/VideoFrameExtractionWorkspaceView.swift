import OSLog
import SwiftUI

struct VideoFrameExtractionWorkspaceView: View {
    let session: ToolSession?

    @StateObject private var importController = VideoImportController()
    @StateObject private var browserModel = ThumbnailBrowserViewModel()
    @StateObject private var previewController = PreviewController()
    @State private var exportSettings = VideoExportSettings()
    @State private var isShowingExportOptions = false

    init(
        session: ToolSession? = nil,
        importController: VideoImportController = VideoImportController(),
        browserModel: ThumbnailBrowserViewModel = ThumbnailBrowserViewModel()
    ) {
        self.session = session
        _importController = StateObject(wrappedValue: importController)
        _browserModel = StateObject(wrappedValue: browserModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Button("Import Video") {
                    importController.promptForVideoImport()
                }

                Spacer()

                Button("Export") {
                    isShowingExportOptions = true
                }
                    .disabled(browserModel.exportSelection.isEmpty)
                    .accessibilityIdentifier("video-export-button")
            }

            FileDropZone(title: "Drop a video here") { urls in
                guard let firstSupportedURL = urls.first(where: importController.isSupportedVideoURL(_:)) else {
                    return
                }

                importController.importVideo(firstSupportedURL)
            }

            if let importedVideoURL = importController.importedVideoURL {
                VStack(alignment: .leading, spacing: 16) {
                    Text(importedVideoURL.lastPathComponent)
                        .font(.headline)
                    candidateBrowser
                }
            } else {
                ContentUnavailableView("No Video Loaded", systemImage: "film")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .sheet(isPresented: $isShowingExportOptions) {
            ExportOptionsView(
                settings: $exportSettings,
                onSelectFormat: handleExportSelection(_:)
            )
            .frame(minWidth: 360, minHeight: 240)
        }
        .onChange(of: importController.importedVideoURL) { _, importedVideoURL in
            guard importedVideoURL != nil else {
                browserModel.loadCandidates([])
                return
            }

            browserModel.loadCandidates(
                FrameCandidateService().selectCandidates(
                    from: mockFrameSamples,
                    minimumDelta: 0.18
                )
            )
        }
    }

    private func handleExportSelection(_ format: VideoExportFormat) {
        exportSettings.format = format
        session?.recordExport(fileNames: ["wallpaper.\(format.rawValue.lowercased())"])
        AppLogger.export.info("Queued export using format \(format.rawValue, privacy: .public)")
        isShowingExportOptions = false
    }

    private var candidateBrowser: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Candidate Frames")
                .font(.title3.weight(.semibold))

            if browserModel.candidates.isEmpty {
                ContentUnavailableView(
                    "No Frame Candidates Yet",
                    systemImage: "rectangle.stack.badge.play",
                    description: Text("Candidate thumbnails will appear here after analysis.")
                )
                .frame(maxWidth: .infinity, minHeight: 240)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                        ForEach(browserModel.candidates) { candidate in
                            CandidateThumbnailCard(
                                candidate: candidate,
                                isFocused: browserModel.focusedCandidateID == candidate.id,
                                isSelected: browserModel.isSelected(candidate),
                                onFocus: { browserModel.focus(candidate) },
                                onToggleSelection: { browserModel.toggleSelection(for: candidate) }
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct ExportOptionsView: View {
    @Binding var settings: VideoExportSettings
    let onSelectFormat: (VideoExportFormat) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Export Options")
                .font(.title2.weight(.semibold))

            Picker("Wallpaper Fit", selection: $settings.fitMode) {
                ForEach(WallpaperFitMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text("Choose Format")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(VideoExportFormat.allCases, id: \.self) { format in
                    Button(format.rawValue) {
                        onSelectFormat(format)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Spacer()
        }
        .padding(24)
    }
}

private struct CandidateThumbnailCard: View {
    let candidate: VideoFrameCandidate
    let isFocused: Bool
    let isSelected: Bool
    let onFocus: () -> Void
    let onToggleSelection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(nsColor: .windowBackgroundColor),
                            Color.accentColor.opacity(0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topLeading) {
                    Text(candidate.formattedTimestamp)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(12)
                }
                .frame(height: 180)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.formattedTimestamp)
                        .font(.headline)
                    Text("Score \(candidate.score, format: .number.precision(.fractionLength(2)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(isSelected ? "Selected" : "Select") {
                    onToggleSelection()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isFocused ? Color.accentColor : .clear, lineWidth: 2)
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture(perform: onFocus)
    }
}

private let mockFrameSamples = [
    VideoFrameSample(time: 0.0, scoreSeed: 0.08),
    VideoFrameSample(time: 1.5, scoreSeed: 0.14),
    VideoFrameSample(time: 4.0, scoreSeed: 0.42),
    VideoFrameSample(time: 8.0, scoreSeed: 0.73),
    VideoFrameSample(time: 12.0, scoreSeed: 0.91),
]

private extension VideoFrameCandidate {
    var formattedTimestamp: String {
        let totalSeconds = Int(time.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

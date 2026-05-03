import OSLog
import SwiftUI

struct VideoFrameExtractionWorkspaceView: View {
    let session: ToolSession?

    @StateObject private var importController = VideoImportController()
    @StateObject private var browserModel = ThumbnailBrowserViewModel()
    @StateObject private var previewController = PreviewController()
    @State private var exportSettings = VideoExportSettings()
    @State private var isShowingExportOptions = false
    @State private var isAnalyzingCandidates = false
    @State private var analysisErrorMessage: String?

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

                Button("Preview") {
                    previewController.toggleLargePreview()
                }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(focusedCandidate == nil)
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
        .sheet(isPresented: $previewController.isShowingLargePreview) {
            LargePreviewView(candidate: focusedCandidate)
                .frame(minWidth: 560, minHeight: 420)
        }
        .onChange(of: importController.importedVideoURL) { _, importedVideoURL in
            guard let importedVideoURL else {
                browserModel.loadCandidates([])
                analysisErrorMessage = nil
                isAnalyzingCandidates = false
                return
            }

            let service = FrameCandidateService()
            isAnalyzingCandidates = true
            analysisErrorMessage = nil

            Task {
                do {
                    let samples = try await service.loadSamples(from: importedVideoURL, count: 12)
                    let candidates = service.selectCandidates(from: samples, minimumDelta: 0.15)
                    await MainActor.run {
                        browserModel.loadCandidates(candidates)
                        isAnalyzingCandidates = false
                    }
                } catch {
                    let fallbackCandidates = service.selectCandidates(from: mockFrameSamples, minimumDelta: 0.18)
                    await MainActor.run {
                        browserModel.loadCandidates(fallbackCandidates)
                        analysisErrorMessage = "Unable to analyze this video yet. Showing placeholder candidates."
                        isAnalyzingCandidates = false
                    }
                    AppLogger.videoModule.error("Frame analysis fallback: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    private func handleExportSelection(_ format: VideoExportFormat) {
        exportSettings.format = format
        session?.recordExport(fileNames: ["wallpaper.\(format.rawValue.lowercased())"])
        AppLogger.export.info("Queued export using format \(format.rawValue, privacy: .public)")
        isShowingExportOptions = false
    }

    private var focusedCandidate: VideoFrameCandidate? {
        browserModel.candidates.first { $0.id == browserModel.focusedCandidateID }
    }

    private var candidateBrowser: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Candidate Frames")
                .font(.title3.weight(.semibold))

            if isAnalyzingCandidates {
                ProgressView("Analyzing video frames...")
                    .frame(maxWidth: .infinity, minHeight: 240)
            } else if browserModel.candidates.isEmpty {
                ContentUnavailableView(
                    "No Frame Candidates Yet",
                    systemImage: "rectangle.stack.badge.play",
                    description: Text("Candidate thumbnails will appear here after analysis.")
                )
                .frame(maxWidth: .infinity, minHeight: 240)
            } else {
                if let analysisErrorMessage {
                    Text(analysisErrorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

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

private struct LargePreviewView: View {
    let candidate: VideoFrameCandidate?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Still Preview")
                .font(.title2.weight(.semibold))

            if let candidate {
                ZStack(alignment: .bottomLeading) {
                    previewImage(for: candidate)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(candidate.formattedTimestamp)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                        Text("Score \(candidate.score, format: .number.precision(.fractionLength(2)))")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(24)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                }
            } else {
                ContentUnavailableView("No Frame Focused", systemImage: "photo")
            }
        }
        .padding(24)
    }

    @ViewBuilder
    private func previewImage(for candidate: VideoFrameCandidate) -> some View {
        if let thumbnailImage = candidate.thumbnailImage {
            Image(nsImage: thumbnailImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.92))
        } else {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.32), Color(nsColor: .windowBackgroundColor)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
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
            thumbnailSurface
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

    @ViewBuilder
    private var thumbnailSurface: some View {
        if let thumbnailImage = candidate.thumbnailImage {
            Image(nsImage: thumbnailImage)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipped()
        } else {
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
                .frame(height: 180)
        }
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

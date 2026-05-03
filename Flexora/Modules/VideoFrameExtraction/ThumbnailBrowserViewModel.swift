import Combine
import Foundation

final class ThumbnailBrowserViewModel: ObservableObject {
    @Published var candidates: [VideoFrameCandidate] = []
    @Published var focusedCandidateID: VideoFrameCandidate.ID?
    @Published var exportSelection: [VideoFrameCandidate] = []

    func loadCandidates(_ candidates: [VideoFrameCandidate]) {
        self.candidates = candidates
        focusedCandidateID = candidates.first?.id
        exportSelection = []
    }

    func focus(_ candidate: VideoFrameCandidate) {
        focusedCandidateID = candidate.id
    }

    func isSelected(_ candidate: VideoFrameCandidate) -> Bool {
        exportSelection.contains(candidate)
    }

    func toggleSelection(for candidate: VideoFrameCandidate) {
        if let index = exportSelection.firstIndex(of: candidate) {
            exportSelection.remove(at: index)
        } else {
            exportSelection.append(candidate)
        }
    }
}

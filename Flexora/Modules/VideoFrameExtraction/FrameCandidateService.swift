import Foundation

struct FrameCandidateService {
    func selectCandidates(from samples: [VideoFrameSample], minimumDelta: Double) -> [VideoFrameCandidate] {
        guard let first = samples.first else { return [] }

        var candidates = [VideoFrameCandidate(time: first.time, score: first.scoreSeed)]
        var previousScore = first.scoreSeed

        for sample in samples.dropFirst() where abs(sample.scoreSeed - previousScore) >= minimumDelta {
            candidates.append(VideoFrameCandidate(time: sample.time, score: sample.scoreSeed))
            previousScore = sample.scoreSeed
        }

        return candidates
    }
}

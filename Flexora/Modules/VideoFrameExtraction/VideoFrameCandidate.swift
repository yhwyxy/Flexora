import Foundation

struct VideoFrameSample: Equatable {
    let time: TimeInterval
    let scoreSeed: Double
}

struct VideoFrameCandidate: Identifiable, Equatable {
    let id: UUID
    let time: TimeInterval
    let score: Double

    init(id: UUID = UUID(), time: TimeInterval, score: Double) {
        self.id = id
        self.time = time
        self.score = score
    }
}

import AppKit
import Foundation

struct VideoFrameSample: Equatable {
    let time: TimeInterval
    let scoreSeed: Double
    let thumbnailImage: NSImage?

    init(time: TimeInterval, scoreSeed: Double, thumbnailImage: NSImage? = nil) {
        self.time = time
        self.scoreSeed = scoreSeed
        self.thumbnailImage = thumbnailImage
    }

    static func == (lhs: VideoFrameSample, rhs: VideoFrameSample) -> Bool {
        lhs.time == rhs.time && lhs.scoreSeed == rhs.scoreSeed
    }
}

struct VideoFrameCandidate: Identifiable, Equatable {
    let id: UUID
    let time: TimeInterval
    let score: Double
    let thumbnailImage: NSImage?

    init(id: UUID = UUID(), time: TimeInterval, score: Double, thumbnailImage: NSImage? = nil) {
        self.id = id
        self.time = time
        self.score = score
        self.thumbnailImage = thumbnailImage
    }

    static func == (lhs: VideoFrameCandidate, rhs: VideoFrameCandidate) -> Bool {
        lhs.id == rhs.id && lhs.time == rhs.time && lhs.score == rhs.score
    }
}

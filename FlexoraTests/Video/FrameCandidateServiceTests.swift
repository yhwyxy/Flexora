import AppKit
import Foundation
import Testing
@testable import Flexora

@MainActor
struct FrameCandidateServiceTests {
    @Test func keepsFramesWithMeaningfulVisualChange() {
        let service = FrameCandidateService()
        let samples = [
            VideoFrameSample(time: 0.0, scoreSeed: 0.10),
            VideoFrameSample(time: 1.0, scoreSeed: 0.11),
            VideoFrameSample(time: 2.0, scoreSeed: 0.85),
            VideoFrameSample(time: 3.0, scoreSeed: 0.87),
        ]

        let result = service.selectCandidates(from: samples, minimumDelta: 0.25)
        let times = result.map { $0.time }

        #expect(times == [0.0, 2.0])
    }

    @Test func emptySamplesProduceNoCandidates() {
        let service = FrameCandidateService()

        #expect(service.selectCandidates(from: [], minimumDelta: 0.25).isEmpty)
    }

    @Test func selectedCandidatesPreserveThumbnailImages() {
        let service = FrameCandidateService()
        let thumbnail = NSImage(size: NSSize(width: 12, height: 12))
        let samples = [
            VideoFrameSample(time: 0.0, scoreSeed: 0.10, thumbnailImage: thumbnail),
            VideoFrameSample(time: 1.0, scoreSeed: 0.60, thumbnailImage: thumbnail),
        ]

        let result = service.selectCandidates(from: samples, minimumDelta: 0.25)

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.thumbnailImage != nil })
    }

    @Test func lowVarianceSamplesStillProduceCoverageCandidates() {
        let service = FrameCandidateService()
        let samples = [
            VideoFrameSample(time: 0.0, scoreSeed: 0.10),
            VideoFrameSample(time: 1.0, scoreSeed: 0.11),
            VideoFrameSample(time: 2.0, scoreSeed: 0.12),
            VideoFrameSample(time: 3.0, scoreSeed: 0.13),
        ]

        let result = service.selectCandidates(from: samples, minimumDelta: 0.25)

        #expect(result.map { $0.time } == [0.0, 1.0, 2.0, 3.0])
    }
}

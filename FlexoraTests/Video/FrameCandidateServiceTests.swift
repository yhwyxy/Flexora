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
}

import AVFoundation
import AppKit
import Foundation

struct FrameCandidateService {
    func loadSamples(from url: URL, count: Int) async throws -> [VideoFrameSample] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let totalSeconds = duration.seconds
        guard totalSeconds > 0 else { return [] }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let times = (0..<count).map { index in
            let second = totalSeconds * Double(index) / Double(max(count - 1, 1))
            return NSValue(time: CMTime(seconds: second, preferredTimescale: 600))
        }

        var samples: [VideoFrameSample] = []
        samples.reserveCapacity(times.count)

        for timeValue in times {
            let time = timeValue.timeValue
            let (image, _) = try await generator.image(at: time)
            let scoreSeed = Self.quickDifferenceSeed(from: image)
            let thumbnailImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
            samples.append(
                VideoFrameSample(
                    time: time.seconds,
                    scoreSeed: scoreSeed,
                    thumbnailImage: thumbnailImage
                )
            )
        }

        return samples
    }

    func selectCandidates(from samples: [VideoFrameSample], minimumDelta: Double) -> [VideoFrameCandidate] {
        guard let first = samples.first else { return [] }

        var candidates = [candidate(from: first)]
        var previousScore = first.scoreSeed

        for sample in samples.dropFirst() where abs(sample.scoreSeed - previousScore) >= minimumDelta {
            candidates.append(candidate(from: sample))
            previousScore = sample.scoreSeed
        }

        let minimumCoverageCount = min(4, samples.count)
        if candidates.count < minimumCoverageCount {
            candidates = coverageCandidates(from: samples, count: minimumCoverageCount)
        }

        return candidates
    }

    private func candidate(from sample: VideoFrameSample) -> VideoFrameCandidate {
        VideoFrameCandidate(
            time: sample.time,
            score: sample.scoreSeed,
            thumbnailImage: sample.thumbnailImage
        )
    }

    private func coverageCandidates(from samples: [VideoFrameSample], count: Int) -> [VideoFrameCandidate] {
        guard count > 0 else { return [] }

        let indices = (0..<count).map { index in
            Int(round(Double(index) * Double(samples.count - 1) / Double(max(count - 1, 1))))
        }

        var seen = Set<Int>()
        return indices.compactMap { index in
            guard seen.insert(index).inserted else { return nil }
            return candidate(from: samples[index])
        }
    }

    static func quickDifferenceSeed(from image: CGImage) -> Double {
        guard
            let dataProvider = image.dataProvider,
            let data = dataProvider.data,
            let bytes = CFDataGetBytePtr(data)
        else {
            return Double(image.width * image.height).squareRoot() / 1000.0
        }

        let width = image.width
        let height = image.height
        let bytesPerRow = image.bytesPerRow
        let bytesPerPixel = max(image.bitsPerPixel / 8, 4)
        let sampleColumns = 6
        let sampleRows = 6
        var accumulator = 0.0

        for row in 0..<sampleRows {
            let y = height > 1 ? (row * (height - 1)) / max(sampleRows - 1, 1) : 0
            for column in 0..<sampleColumns {
                let x = width > 1 ? (column * (width - 1)) / max(sampleColumns - 1, 1) : 0
                let offset = y * bytesPerRow + x * bytesPerPixel
                let red = Double(bytes[offset])
                let green = Double(bytes[offset + 1])
                let blue = Double(bytes[offset + 2])
                let luma = (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255.0
                accumulator += luma * Double((row + 1) * (column + 1))
            }
        }

        return accumulator / Double(sampleColumns * sampleRows)
    }
}

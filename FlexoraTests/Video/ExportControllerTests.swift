import AppKit
import Foundation
import ImageIO
import Testing
@testable import Flexora

struct ExportControllerTests {
    @Test func supportsPngJpegAndHeic() {
        #expect(VideoExportFormat.allCases == [.png, .jpeg, .heic])
    }

    @Test func historyStoresCompletedExportEntries() {
        let session = ToolSession(moduleID: "video")
        session.recordExport(fileNames: ["wallpaper-1.heic"])

        #expect(session.history.count == 1)
        #expect(session.history.first?.fileNames == ["wallpaper-1.heic"])
    }

    @Test func heicFailureFallsBackToUserVisibleError() {
        let controller = ExportController()
        let message = controller.userFacingError(for: .heicEncodingUnavailable)

        #expect(message == "HEIC export is unavailable for this file. Choose PNG or JPEG instead.")
    }

    @Test func exportRejectsFileDestination() throws {
        let controller = ExportController()
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("txt")

        try Data("preview".utf8).write(to: fileURL)

        #expect(throws: ExportControllerError.destinationNotDirectory) {
            try controller.validateDestination(fileURL)
        }
    }

    @Test func exportRejectsMissingDestinationDirectory() {
        let controller = ExportController()
        let missingDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        #expect(throws: ExportControllerError.destinationMissing) {
            try controller.validateDestination(missingDirectory)
        }
    }

    @Test func validateDestinationAllowsExistingDirectoryWithoutProbeWrite() throws {
        let controller = ExportController()
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        #expect(throws: Never.self) {
            try controller.validateDestination(directory)
        }
    }

    @Test func exportRejectsReadOnlyDestinationDirectory() throws {
        let controller = ExportController()
        let image = makeImage()
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path)

        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
            try? FileManager.default.removeItem(at: directory)
        }

        #expect(throws: ExportControllerError.destinationNotWritable) {
            try controller.export(
                image: image,
                to: directory,
                fileName: "wallpaper-001",
                settings: VideoExportSettings(format: .png, fitMode: .original)
            )
        }
    }

    @Test func exportRejectsExistingOutputFileWithoutOverwriting() throws {
        let controller = ExportController()
        let image = makeImage()
        let directory = try makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let existingURL = directory
            .appendingPathComponent("wallpaper-001")
            .appendingPathExtension("png")
        let existingData = Data("existing-image-data".utf8)
        try existingData.write(to: existingURL)

        #expect(throws: ExportControllerError.destinationFileExists) {
            try controller.export(
                image: image,
                to: directory,
                fileName: "wallpaper-001",
                settings: VideoExportSettings(format: .png, fitMode: .original)
            )
        }

        #expect(try Data(contentsOf: existingURL) == existingData)
    }

    @Test func exportWritesImageToRequestedFolder() throws {
        let controller = ExportController()
        let image = makeImage()

        let directory = try makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let outputURL = try controller.export(
            image: image,
            to: directory,
            fileName: "wallpaper-001",
            settings: VideoExportSettings(format: .png, fitMode: .original)
        )

        #expect(outputURL.pathExtension == "png")
        #expect(FileManager.default.fileExists(atPath: outputURL.path))
    }

    @Test func exportAppliesWallpaperFitModeToOutputDimensions() throws {
        let controller = ExportController()
        let image = makeImage(size: NSSize(width: 400, height: 300))
        let directory = try makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let originalURL = try controller.export(
            image: image,
            to: directory,
            fileName: "wallpaper-original",
            settings: VideoExportSettings(format: .png, fitMode: .original)
        )
        let cropURL = try controller.export(
            image: image,
            to: directory,
            fileName: "wallpaper-crop",
            settings: VideoExportSettings(format: .png, fitMode: .cropToDesktopAspect)
        )
        let fillURL = try controller.export(
            image: image,
            to: directory,
            fileName: "wallpaper-fill",
            settings: VideoExportSettings(format: .png, fitMode: .fillToDesktopAspect)
        )

        let originalSize = try exportedPixelSize(at: originalURL)
        let cropSize = try exportedPixelSize(at: cropURL)
        let fillSize = try exportedPixelSize(at: fillURL)

        #expect(originalSize.width > 0)
        #expect(originalSize.height > 0)

        #expect(cropSize.width == originalSize.width)
        #expect(cropSize.width * 5 == cropSize.height * 8)
        #expect(cropSize.height < originalSize.height)

        #expect(fillSize.height == originalSize.height)
        #expect(fillSize.width * 5 == fillSize.height * 8)
        #expect(fillSize.width > originalSize.width)
    }

    @Test func destinationErrorsHaveExplicitUserFacingMessages() {
        let controller = ExportController()

        #expect(controller.userFacingError(for: .destinationMissing) == "The selected export folder no longer exists. Choose a different location and try again.")
        #expect(controller.userFacingError(for: .destinationNotDirectory) == "The selected export location is not a folder. Choose a different location and try again.")
        #expect(controller.userFacingError(for: .destinationNotWritable) == "The selected export folder is not writable. Choose a different location and try again.")
        #expect(controller.userFacingError(for: .destinationFileExists) == "A file with the same name already exists in the chosen export folder. Remove it, rename it, or choose a different folder and try again.")
    }

    private func makeImage(size: NSSize = NSSize(width: 16, height: 16)) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.systemBlue.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        return image
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func exportedPixelSize(at url: URL) throws -> (width: Int, height: Int) {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Int,
            let height = properties[kCGImagePropertyPixelHeight] as? Int
        else {
            throw ExportControllerError.destinationNotWritable
        }

        return (width, height)
    }
}

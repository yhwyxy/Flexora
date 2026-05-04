import AppKit
import Foundation
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

    @Test func exportRejectsReadOnlyDestinationDirectory() throws {
        let controller = ExportController()
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: directory.path)

        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
            try? FileManager.default.removeItem(at: directory)
        }

        #expect(throws: ExportControllerError.destinationNotWritable) {
            try controller.validateDestination(directory)
        }
    }

    @Test func exportWritesImageToRequestedFolder() throws {
        let controller = ExportController()
        let image = makeImage()

        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let outputURL = try controller.export(
            image: image,
            to: directory,
            fileName: "wallpaper-001",
            settings: VideoExportSettings(format: .png, fitMode: .original)
        )

        #expect(outputURL.pathExtension == "png")
        #expect(FileManager.default.fileExists(atPath: outputURL.path))
    }

    @Test func destinationErrorsHaveExplicitUserFacingMessages() {
        let controller = ExportController()

        #expect(controller.userFacingError(for: .destinationMissing) == "The selected export folder no longer exists. Choose a different location and try again.")
        #expect(controller.userFacingError(for: .destinationNotDirectory) == "The selected export location is not a folder. Choose a different location and try again.")
        #expect(controller.userFacingError(for: .destinationNotWritable) == "The selected export folder is not writable. Choose a different location and try again.")
    }

    private func makeImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus()
        NSColor.systemBlue.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 16, height: 16)).fill()
        image.unlockFocus()
        return image
    }
}

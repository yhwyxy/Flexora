import AppKit
import Foundation
import OSLog

enum ExportControllerError: Error, Equatable {
    case destinationMissing
    case destinationNotDirectory
    case destinationNotWritable
    case destinationFileExists
    case heicEncodingUnavailable
    case missingFrameImage
}

struct ExportController {
    private static let desktopAspectRatio: CGFloat = 16.0 / 10.0

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func export(image: NSImage, to url: URL, fileName: String, settings: VideoExportSettings) throws -> URL {
        try withDestinationAccess(to: url) { destinationURL in
            try validateDestinationWithoutAccessCheck(destinationURL)

            let outputURL = makeOutputURL(
                destinationURL: destinationURL,
                fileName: fileName,
                format: settings.format
            )
            try validateOutputDoesNotExist(outputURL)

            let adaptedImage = try adaptedImage(for: image, fitMode: settings.fitMode)
            let data = try ImageExportEncoding.data(for: adaptedImage, format: settings.format)

            do {
                try data.write(to: outputURL, options: .withoutOverwriting)
            } catch {
                logWriteFailure(error, destinationURL: destinationURL, outputURL: outputURL)
                throw mapWriteError(error)
            }

            return outputURL
        }
    }

    func validateDestination(_ url: URL) throws {
        try withDestinationAccess(to: url) { destinationURL in
            try validateDestinationWithoutAccessCheck(destinationURL)
        }
    }

    func userFacingError(for error: ExportControllerError) -> String {
        switch error {
        case .destinationMissing:
            return "The selected export folder no longer exists. Choose a different location and try again."
        case .destinationNotDirectory:
            return "The selected export location is not a folder. Choose a different location and try again."
        case .destinationFileExists:
            return "A file with the same name already exists in the chosen export folder. Remove it, rename it, or choose a different folder and try again."
        case .heicEncodingUnavailable:
            return "HEIC export is unavailable for this file. Choose PNG or JPEG instead."
        case .destinationNotWritable:
            return "The selected export folder is not writable. Choose a different location and try again."
        case .missingFrameImage:
            return "The selected frame does not have image data available for export."
        }
    }

    private func withDestinationAccess<T>(to url: URL, _ body: (URL) throws -> T) throws -> T {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try body(url)
    }

    private func validateDestinationWithoutAccessCheck(_ url: URL) throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw ExportControllerError.destinationMissing
        }

        guard isDirectory.boolValue else {
            throw ExportControllerError.destinationNotDirectory
        }
    }

    private func makeOutputURL(destinationURL: URL, fileName: String, format: VideoExportFormat) -> URL {
        destinationURL
            .appendingPathComponent(fileName)
            .appendingPathExtension(format.rawValue.lowercased())
    }

    private func validateOutputDoesNotExist(_ outputURL: URL) throws {
        guard !fileManager.fileExists(atPath: outputURL.path) else {
            throw ExportControllerError.destinationFileExists
        }
    }

    private func adaptedImage(for image: NSImage, fitMode: WallpaperFitMode) throws -> NSImage {
        guard fitMode != .original else {
            return image
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ExportControllerError.destinationNotWritable
        }

        let sourceSize = CGSize(width: cgImage.width, height: cgImage.height)
        let outputSize = outputSize(for: sourceSize, fitMode: fitMode)
        let outputRect = CGRect(origin: .zero, size: outputSize)
        let image = NSImage(size: NSSize(width: outputSize.width, height: outputSize.height))

        image.lockFocus()
        NSColor.black.setFill()
        outputRect.fill()

        switch fitMode {
        case .original:
            break
        case .cropToDesktopAspect:
            let cropRect = cropRect(for: sourceSize)
            NSImage(cgImage: cgImage, size: NSSize(width: sourceSize.width, height: sourceSize.height))
                .draw(in: outputRect, from: cropRect, operation: .copy, fraction: 1)
        case .fillToDesktopAspect:
            let fittedRect = fittedRect(sourceSize: sourceSize, canvasSize: outputSize)
            NSImage(cgImage: cgImage, size: NSSize(width: sourceSize.width, height: sourceSize.height))
                .draw(in: fittedRect, from: CGRect(origin: .zero, size: sourceSize), operation: .copy, fraction: 1)
        }
        image.unlockFocus()

        return image
    }

    private func outputSize(for sourceSize: CGSize, fitMode: WallpaperFitMode) -> CGSize {
        let sourceAspectRatio = sourceSize.width / sourceSize.height

        switch fitMode {
        case .original:
            return sourceSize
        case .cropToDesktopAspect:
            if sourceAspectRatio > Self.desktopAspectRatio {
                return CGSize(width: sourceSize.height * Self.desktopAspectRatio, height: sourceSize.height)
            }

            return CGSize(width: sourceSize.width, height: sourceSize.width / Self.desktopAspectRatio)
        case .fillToDesktopAspect:
            if sourceAspectRatio > Self.desktopAspectRatio {
                return CGSize(width: sourceSize.width, height: sourceSize.width / Self.desktopAspectRatio)
            }

            return CGSize(width: sourceSize.height * Self.desktopAspectRatio, height: sourceSize.height)
        }
    }

    private func cropRect(for sourceSize: CGSize) -> CGRect {
        let croppedSize = outputSize(for: sourceSize, fitMode: .cropToDesktopAspect)

        return CGRect(
            x: (sourceSize.width - croppedSize.width) / 2,
            y: (sourceSize.height - croppedSize.height) / 2,
            width: croppedSize.width,
            height: croppedSize.height
        )
    }

    private func fittedRect(sourceSize: CGSize, canvasSize: CGSize) -> CGRect {
        CGRect(
            x: (canvasSize.width - sourceSize.width) / 2,
            y: (canvasSize.height - sourceSize.height) / 2,
            width: sourceSize.width,
            height: sourceSize.height
        )
    }

    private func logWriteFailure(_ error: Error, destinationURL: URL, outputURL: URL) {
        let nsError = error as NSError
        AppLogger.export.error(
            """
            Export write failed.
            destination: \(destinationURL.path, privacy: .public)
            output: \(outputURL.path, privacy: .public)
            domain: \(nsError.domain, privacy: .public)
            code: \(nsError.code, privacy: .public)
            description: \(nsError.localizedDescription, privacy: .public)
            userInfo: \(String(describing: nsError.userInfo), privacy: .public)
            """
        )
    }

    private func mapWriteError(_ error: Error) -> Error {
        guard let cocoaError = error as? CocoaError else {
            return error
        }

        switch cocoaError.code {
        case .fileNoSuchFile:
            return ExportControllerError.destinationMissing
        case .fileWriteFileExists:
            return ExportControllerError.destinationFileExists
        case .fileWriteNoPermission, .fileWriteVolumeReadOnly:
            return ExportControllerError.destinationNotWritable
        default:
            return error
        }
    }
}

import AppKit
import Foundation

enum ExportControllerError: Error, Equatable {
    case destinationMissing
    case destinationNotDirectory
    case destinationNotWritable
    case heicEncodingUnavailable
    case missingFrameImage
}

struct ExportController {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func export(image: NSImage, to url: URL, fileName: String, settings: VideoExportSettings) throws -> URL {
        try withDestinationAccess(to: url) { destinationURL in
            try validateDestinationWithoutAccessCheck(destinationURL)

            let data = try ImageExportEncoding.data(for: image, format: settings.format)
            let outputURL = destinationURL
                .appendingPathComponent(fileName)
                .appendingPathExtension(settings.format.rawValue.lowercased())

            do {
                try data.write(to: outputURL, options: .atomic)
            } catch {
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

        let probeURL = url.appendingPathComponent(".flexora-write-check-\(UUID().uuidString)")

        do {
            try Data().write(to: probeURL, options: .withoutOverwriting)
            try fileManager.removeItem(at: probeURL)
        } catch {
            throw ExportControllerError.destinationNotWritable
        }
    }

    private func mapWriteError(_ error: Error) -> Error {
        guard let cocoaError = error as? CocoaError else {
            return error
        }

        switch cocoaError.code {
        case .fileNoSuchFile:
            return ExportControllerError.destinationMissing
        case .fileWriteNoPermission, .fileWriteVolumeReadOnly:
            return ExportControllerError.destinationNotWritable
        default:
            return error
        }
    }
}

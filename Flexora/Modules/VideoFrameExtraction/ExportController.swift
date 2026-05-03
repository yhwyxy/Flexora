import AppKit
import Foundation

enum ExportControllerError: Error {
    case destinationNotWritable
    case heicEncodingUnavailable
}

struct ExportController {
    func export(image: NSImage, to url: URL, settings: VideoExportSettings) throws -> URL {
        let data = try ImageExportEncoding.data(for: image, format: settings.format)
        let outputURL = url
            .appendingPathComponent("wallpaper")
            .appendingPathExtension(settings.format.rawValue.lowercased())
        try data.write(to: outputURL, options: .atomic)
        return outputURL
    }

    func userFacingError(for error: ExportControllerError) -> String {
        switch error {
        case .heicEncodingUnavailable:
            return "HEIC export is unavailable for this file. Choose PNG or JPEG instead."
        case .destinationNotWritable:
            return "The selected export folder is not writable. Choose a different location and try again."
        }
    }
}

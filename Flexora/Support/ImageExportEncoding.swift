import AppKit
import ImageIO
import UniformTypeIdentifiers

enum ImageExportEncoding {
    static func data(for image: NSImage, format: VideoExportFormat) throws -> Data {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ExportControllerError.destinationNotWritable
        }

        if format == .heic, !isHEICAvailable {
            throw ExportControllerError.heicEncodingUnavailable
        }

        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                data,
                format.utType.identifier as CFString,
                1,
                nil
            )
        else {
            throw ExportControllerError.destinationNotWritable
        }

        let properties: CFDictionary
        switch format {
        case .png, .heic:
            properties = [:] as CFDictionary
        case .jpeg:
            properties = [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary
        }

        CGImageDestinationAddImage(destination, cgImage, properties)
        guard CGImageDestinationFinalize(destination) else {
            throw ExportControllerError.destinationNotWritable
        }

        return data as Data
    }

    private static var isHEICAvailable: Bool {
        let identifiers = CGImageDestinationCopyTypeIdentifiers() as NSArray
        return identifiers.contains(UTType.heic.identifier)
    }
}

private extension VideoExportFormat {
    var utType: UTType {
        switch self {
        case .png:
            return .png
        case .jpeg:
            return .jpeg
        case .heic:
            return .heic
        }
    }
}

import Foundation
import OSLog

enum AppLogger {
    static let videoModule = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Flexora",
        category: "VideoModule"
    )

    static let export = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Flexora",
        category: "Export"
    )
}

import Foundation
import OSLog

enum AppLogger {
    static let export = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Flexora",
        category: "Export"
    )
}

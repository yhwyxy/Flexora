import Foundation

public final class ToolSession {
    public struct HistoryEntry: Identifiable, Equatable {
        public let id = UUID()
        public let createdAt = Date()
        public let fileNames: [String]

        public init(fileNames: [String]) {
            self.fileNames = fileNames
        }
    }

    public let moduleID: String
    public private(set) var history: [HistoryEntry] = []

    public init(moduleID: String) {
        self.moduleID = moduleID
    }

    public func recordExport(fileNames: [String]) {
        history.insert(HistoryEntry(fileNames: fileNames), at: 0)
    }
}

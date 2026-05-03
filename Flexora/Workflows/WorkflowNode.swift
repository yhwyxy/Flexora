public struct WorkflowNode: Equatable, Identifiable, Sendable {
    public let id: String
    public let moduleID: String
    public let title: String

    public init(id: String, moduleID: String, title: String) {
        self.id = id
        self.moduleID = moduleID
        self.title = title
    }
}

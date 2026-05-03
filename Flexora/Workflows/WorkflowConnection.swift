public struct WorkflowConnection: Equatable, Identifiable, Sendable {
    public let id: String
    public let sourceNodeID: String
    public let destinationNodeID: String

    public init(id: String, sourceNodeID: String, destinationNodeID: String) {
        self.id = id
        self.sourceNodeID = sourceNodeID
        self.destinationNodeID = destinationNodeID
    }
}

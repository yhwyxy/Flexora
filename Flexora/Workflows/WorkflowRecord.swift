public struct WorkflowRecord: Equatable, Identifiable, Sendable {
    public let id: String
    public var title: String
    public var summary: String
    public var source: WorkflowSource
    public var tags: [WorkflowTagRecord]
    public var nodes: [WorkflowNode]
    public var connections: [WorkflowConnection]

    public init(
        id: String,
        title: String,
        summary: String,
        source: WorkflowSource,
        tags: [WorkflowTagRecord],
        nodes: [WorkflowNode],
        connections: [WorkflowConnection]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.source = source
        self.tags = tags
        self.nodes = nodes
        self.connections = connections
    }
}

public struct WorkflowLibrary: Equatable, Sendable {
    public struct Section: Equatable, Sendable {
        public let tag: WorkflowTagRecord?
        public let workflows: [WorkflowRecord]

        public init(tag: WorkflowTagRecord?, workflows: [WorkflowRecord]) {
            self.tag = tag
            self.workflows = workflows
        }

        public var title: String {
            tag?.name ?? "Untagged"
        }
    }

    public let workflows: [WorkflowRecord]
    public let sections: [Section]

    public init(workflows: [WorkflowRecord], sections: [Section]) {
        self.workflows = workflows
        self.sections = sections
    }
}

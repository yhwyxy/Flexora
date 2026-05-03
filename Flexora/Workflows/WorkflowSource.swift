public enum WorkflowSource: Equatable, Sendable {
    case moduleDefault(moduleID: String)
    case userAuthored
}

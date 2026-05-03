public enum WorkflowAvailability: Equatable, Sendable {
    case available
    case unavailable(requiredModuleIDs: [String])
}

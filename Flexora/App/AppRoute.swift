public enum AppRoute: Equatable {
    public enum TopLevelRoute: Equatable {
        case home
        case workshop
        case modules
    }

    case home
    case workshop
    case modules
    case task(workflowID: String)
    case workflowEditor(workflowID: String)

    public var topLevelRoute: TopLevelRoute? {
        switch self {
        case .home:
            return .home
        case .workshop:
            return .workshop
        case .modules:
            return .modules
        case .task, .workflowEditor:
            return nil
        }
    }

    public var workflowID: String? {
        switch self {
        case .task(let workflowID), .workflowEditor(let workflowID):
            return workflowID
        case .home, .workshop, .modules:
            return nil
        }
    }

    public var isWorkflowEditor: Bool {
        if case .workflowEditor = self {
            return true
        }

        return false
    }

    public var isTask: Bool {
        if case .task = self { return true }
        return false
    }

    public static func defaultWorkflowID(forModuleID moduleID: String) -> String {
        "module.\(moduleID).default"
    }
}

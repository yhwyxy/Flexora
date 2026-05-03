public enum AppRoute: Equatable {
    case moduleChooser
    case workspace(moduleID: String)

    private static let taskPrefix = "__task__:"
    private static let workflowEditorPrefix = "__workflowEditor__:"

    public static var home: AppRoute { .moduleChooser }
    public static var workshop: AppRoute { .moduleChooser }
    public static var modules: AppRoute { .moduleChooser }

    public static func task(workflowID: String) -> AppRoute {
        .workspace(moduleID: taskTarget(forWorkflowID: workflowID))
    }

    public static func workflowEditor(workflowID: String) -> AppRoute {
        .workspace(moduleID: workflowEditorPrefix + workflowID)
    }

    public var workflowID: String? {
        switch self {
        case .moduleChooser:
            return nil
        case .workspace(let moduleID):
            if moduleID.hasPrefix(Self.workflowEditorPrefix) {
                return String(moduleID.dropFirst(Self.workflowEditorPrefix.count))
            }

            if moduleID.hasPrefix(Self.taskPrefix) {
                return String(moduleID.dropFirst(Self.taskPrefix.count))
            }

            return Self.defaultWorkflowID(forModuleID: moduleID)
        }
    }

    public var isWorkflowEditor: Bool {
        guard case let .workspace(moduleID) = self else {
            return false
        }

        return moduleID.hasPrefix(Self.workflowEditorPrefix)
    }

    public var isTask: Bool {
        workflowID != nil && isWorkflowEditor == false
    }

    public var moduleID: String? {
        guard case let .workspace(moduleID) = self else {
            return nil
        }

        guard moduleID.hasPrefix(Self.taskPrefix) == false, moduleID.hasPrefix(Self.workflowEditorPrefix) == false else {
            return nil
        }

        return moduleID
    }

    public static func defaultWorkflowID(forModuleID moduleID: String) -> String {
        "module.\(moduleID).default"
    }

    private static func taskTarget(forWorkflowID workflowID: String) -> String {
        guard
            workflowID.hasPrefix("module."),
            workflowID.hasSuffix(".default")
        else {
            return taskPrefix + workflowID
        }

        let start = workflowID.index(workflowID.startIndex, offsetBy: "module.".count)
        let end = workflowID.index(workflowID.endIndex, offsetBy: -".default".count)
        return String(workflowID[start..<end])
    }
}

public enum AppRoute: Equatable {
    public enum TopLevelRoute: Equatable {
        case home
        case workshop
        case modules
    }

    case moduleChooser
    case workspace(moduleID: String)

    private nonisolated static let homePrefix = "__home__"
    private nonisolated static let workshopPrefix = "__workshop__"
    private nonisolated static let modulesPrefix = "__modules__"
    private nonisolated static let taskPrefix = "__task__:"
    private nonisolated static let workflowEditorPrefix = "__workflowEditor__:"

    public nonisolated static let home: AppRoute = .workspace(moduleID: homePrefix)
    public nonisolated static let workshop: AppRoute = .workspace(moduleID: workshopPrefix)
    public nonisolated static let modules: AppRoute = .workspace(moduleID: modulesPrefix)

    public nonisolated static func task(workflowID: String) -> AppRoute {
        .workspace(moduleID: taskPrefix + workflowID)
    }

    public nonisolated static func workflowEditor(workflowID: String) -> AppRoute {
        .workspace(moduleID: workflowEditorPrefix + workflowID)
    }

    public var topLevelRoute: TopLevelRoute? {
        guard case let .workspace(moduleID) = self else { return nil }
        switch moduleID {
        case Self.homePrefix:
            return .home
        case Self.workshopPrefix:
            return .workshop
        case Self.modulesPrefix:
            return .modules
        default:
            return nil
        }
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

        guard
            moduleID.hasPrefix(Self.taskPrefix) == false,
            moduleID.hasPrefix(Self.workflowEditorPrefix) == false,
            moduleID.hasPrefix(Self.homePrefix) == false,
            moduleID.hasPrefix(Self.workshopPrefix) == false,
            moduleID.hasPrefix(Self.modulesPrefix) == false
        else {
            return nil
        }

        return moduleID
    }

    public static func defaultWorkflowID(forModuleID moduleID: String) -> String {
        "module.\(moduleID).default"
    }
}

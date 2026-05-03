@MainActor
public final class AppModel {
    public let runtime: ModuleRuntime
    public var route: AppRoute
    public private(set) var activeSession: ToolSession?

    public init(runtime: ModuleRuntime, route: AppRoute = .moduleChooser) {
        self.runtime = runtime
        self.route = route
        self.runtime.onActiveModuleChange = { [weak self] activeModuleID in
            self?.applyRuntimeState(activeModuleID: activeModuleID)
        }
        applyRuntimeState(activeModuleID: runtime.activeModuleID)
    }

    public func openModule(withID id: String) {
        guard runtime.activateModule(withID: id) != nil else {
            return
        }

        if activeSession?.moduleID != id {
            activeSession = ToolSession(moduleID: id)
        }

        route = .workspace(moduleID: id)
    }

    public func syncStateFromRuntime() {
        applyRuntimeState(activeModuleID: runtime.activeModuleID)
    }

    private func applyRuntimeState(activeModuleID: String?) {
        guard let activeModuleID else {
            activeSession = nil
            route = .moduleChooser
            return
        }

        if activeSession?.moduleID != activeModuleID {
            activeSession = ToolSession(moduleID: activeModuleID)
        }

        route = .workspace(moduleID: activeModuleID)
    }
}

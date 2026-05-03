@MainActor
public final class AppModel {
    public let runtime: ModuleRuntime
    public var route: AppRoute
    public private(set) var activeSession: ToolSession?

    public init(runtime: ModuleRuntime, route: AppRoute = .moduleChooser) {
        self.runtime = runtime
        self.route = route
    }

    public func openModule(withID id: String) {
        guard runtime.activateModule(withID: id) != nil else {
            return
        }

        activeSession = ToolSession(moduleID: id)
        route = .workspace(moduleID: id)
    }
}

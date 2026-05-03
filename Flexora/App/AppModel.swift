import Combine
import SwiftUI

@MainActor
public final class AppModel: ObservableObject {
    public let runtime: ModuleRuntime
    @Published public var route: AppRoute
    @Published public private(set) var activeSession: ToolSession?
    private var runtimeCancellable: AnyCancellable?

    public init(runtime: ModuleRuntime, route: AppRoute = .moduleChooser) {
        self.runtime = runtime
        self.route = route
        self.runtimeCancellable = runtime.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
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

    public func setModuleEnabled(_ id: String, isEnabled: Bool) {
        runtime.setModuleEnabled(id, isEnabled: isEnabled)
        applyRuntimeState(activeModuleID: runtime.activeModuleID)
    }

    public func workspaceView(for moduleID: String) -> AnyView {
        guard
            let session = activeSession,
            session.moduleID == moduleID,
            let module = runtime.registeredModules[moduleID]
        else {
            return AnyView(
                ContentUnavailableView("Module Unavailable", systemImage: "square.slash")
            )
        }

        return module.makeWorkspaceView(session: session)
    }

    public static func bootstrap() -> AppModel {
        let runtime = ModuleRuntime()
        let videoModule = VideoFrameExtractionModule()

        runtime.register(module: videoModule)
        runtime.setModuleEnabled(videoModule.descriptor.id, isEnabled: true)

        return AppModel(runtime: runtime)
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

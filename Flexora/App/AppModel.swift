import Combine
import SwiftUI

@MainActor
public final class AppModel: ObservableObject {
    public let runtime: ModuleRuntime
    public let workflowStore: WorkflowStore
    @Published public var route: AppRoute
    @Published public private(set) var activeSession: ToolSession?
    private var runtimeCancellable: AnyCancellable?
    private var workflowStoreCancellable: AnyCancellable?

    public init(
        runtime: ModuleRuntime,
        workflowStore: WorkflowStore? = nil,
        route: AppRoute = .moduleChooser
    ) {
        self.runtime = runtime
        self.workflowStore = workflowStore ?? WorkflowStore()
        self.route = route
        self.runtimeCancellable = runtime.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        self.workflowStoreCancellable = self.workflowStore.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        self.runtime.onActiveModuleChange = { [weak self] _ in
            self?.syncStateFromRuntime()
        }
        syncStateFromRuntime()
    }

    public func openModule(withID id: String) {
        syncDefaultWorkflows()
        let workflowID = AppRoute.defaultWorkflowID(forModuleID: id)

        guard workflowStore.workflows.contains(where: { $0.id == workflowID }) else {
            return
        }

        openWorkflow(withID: workflowID)
    }

    public func openWorkflow(withID workflowID: String) {
        guard workflowStore.workflows.contains(where: { $0.id == workflowID }) else {
            return
        }

        route = .task(workflowID: workflowID)
        activeSession = activeSession(forWorkflowID: workflowID)
    }

    public func editWorkflow(withID workflowID: String) {
        guard workflowStore.workflows.contains(where: { $0.id == workflowID }) else {
            return
        }

        route = .workflowEditor(workflowID: workflowID)
        activeSession = nil
    }

    public func syncStateFromRuntime() {
        syncDefaultWorkflows()

        if let workflowID = route.workflowID {
            if route.isWorkflowEditor {
                activeSession = nil
            } else {
                activeSession = activeSession(forWorkflowID: workflowID)
            }
            return
        }

        guard let activeModuleID = runtime.activeModuleID else {
            activeSession = nil
            return
        }

        route = .task(workflowID: AppRoute.defaultWorkflowID(forModuleID: activeModuleID))
        activeSession = activeSession(forWorkflowID: AppRoute.defaultWorkflowID(forModuleID: activeModuleID))
    }

    public func setModuleEnabled(_ id: String, isEnabled: Bool) {
        runtime.setModuleEnabled(id, isEnabled: isEnabled)
        syncStateFromRuntime()
    }

    private func syncDefaultWorkflows() {
        workflowStore.synchronizeDefaultWorkflows(with: runtime)
    }

    private func activeSession(forWorkflowID workflowID: String) -> ToolSession? {
        guard let workflow = workflowStore.workflows.first(where: { $0.id == workflowID }) else {
            return nil
        }

        let moduleIDs = Array(Set(workflow.nodes.map(\.moduleID))).sorted()
        guard moduleIDs.count == 1, let moduleID = moduleIDs.first else {
            return nil
        }

        guard
            let module = runtime.module(withID: moduleID),
            module.descriptor.capabilities.contains(.workspace),
            runtime.activateModule(withID: moduleID) != nil
        else {
            return nil
        }

        if activeSession?.moduleID == moduleID {
            return activeSession
        }

        return ToolSession(moduleID: moduleID)
    }
}

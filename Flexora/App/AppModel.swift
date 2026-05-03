import Combine
import SwiftUI

@MainActor
public final class AppModel: ObservableObject {
    public let runtime: ModuleRuntime
    public let workflowStore: WorkflowStore
    @Published public var route: AppRoute
    @Published public private(set) var activeSession: ToolSession?
    private var activeSessionWorkflowID: String?
    private var runtimeCancellable: AnyCancellable?
    private var workflowStoreCancellable: AnyCancellable?

    public init(
        runtime: ModuleRuntime,
        workflowStore: WorkflowStore? = nil,
        route: AppRoute = .modules
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
        updateActiveSession(forWorkflowID: workflowID)
    }

    public func editWorkflow(withID workflowID: String) {
        guard workflowStore.workflows.contains(where: { $0.id == workflowID }) else {
            return
        }

        route = .workflowEditor(workflowID: workflowID)
        clearActiveSession()
    }

    public func showHome() {
        showTopLevelRoute(.home)
    }

    public func showWorkshop() {
        showTopLevelRoute(.workshop)
    }

    public func showModules() {
        showTopLevelRoute(.modules)
    }

    public func syncStateFromRuntime() {
        syncDefaultWorkflows()

        guard route.isWorkflowEditor == false else {
            clearActiveSession()
            return
        }

        guard let workflowID = route.workflowID else {
            clearActiveSession()
            return
        }

        updateActiveSession(forWorkflowID: workflowID)
    }

    public func setModuleEnabled(_ id: String, isEnabled: Bool) {
        runtime.setModuleEnabled(id, isEnabled: isEnabled)
        syncStateFromRuntime()
    }

    private func syncDefaultWorkflows() {
        workflowStore.synchronizeDefaultWorkflows(with: runtime)
    }

    private func showTopLevelRoute(_ route: AppRoute) {
        self.route = route
        clearActiveSession()
    }

    private func clearActiveSession() {
        activeSession = nil
        activeSessionWorkflowID = nil
    }

    private func updateActiveSession(forWorkflowID workflowID: String) {
        guard let workflow = workflowStore.workflows.first(where: { $0.id == workflowID }) else {
            clearActiveSession()
            return
        }

        let moduleIDs = Array(Set(workflow.nodes.map(\.moduleID))).sorted()
        guard moduleIDs.count == 1, let moduleID = moduleIDs.first else {
            clearActiveSession()
            return
        }

        guard
            let module = runtime.module(withID: moduleID),
            module.descriptor.capabilities.contains(.workspace),
            runtime.activateModule(withID: moduleID) != nil
        else {
            clearActiveSession()
            return
        }

        if activeSession?.moduleID == moduleID, activeSessionWorkflowID == workflowID {
            return
        }

        activeSession = ToolSession(moduleID: moduleID)
        activeSessionWorkflowID = workflowID
    }
}

import Combine

@MainActor
public final class ModuleRuntime: ObservableObject {
    public var onActiveModuleChange: ((String?) -> Void)?
    @Published public private(set) var registeredModules: [String: ToolModule] = [:]
    @Published public private(set) var enabledModuleIDs: Set<String> = []
    @Published public private(set) var activeModuleID: String?

    public init() {}

    public var availableModules: [ModuleDescriptor] {
        registeredModules.values
            .map(\.descriptor)
            .filter { enabledModuleIDs.contains($0.id) }
            .sorted { $0.name < $1.name }
    }

    public var allModules: [ModuleDescriptor] {
        registeredModules.values
            .map(\.descriptor)
            .sorted { $0.name < $1.name }
    }

    public func isModuleEnabled(_ id: String) -> Bool {
        enabledModuleIDs.contains(id)
    }

    public func register(module: ToolModule) {
        registeredModules[module.descriptor.id] = module
    }

    public func setModuleEnabled(_ id: String, isEnabled: Bool) {
        if isEnabled {
            enabledModuleIDs.insert(id)
            return
        }

        enabledModuleIDs.remove(id)

        if activeModuleID == id {
            registeredModules[id]?.unload()
            activeModuleID = nil
            onActiveModuleChange?(nil)
        }
    }

    @discardableResult
    public func activateModule(withID id: String) -> ToolModule? {
        guard enabledModuleIDs.contains(id), let module = registeredModules[id] else {
            return nil
        }

        if activeModuleID == id {
            return module
        }

        if let activeModuleID, activeModuleID != id {
            registeredModules[activeModuleID]?.unload()
        }

        module.load()
        activeModuleID = id
        onActiveModuleChange?(id)
        return module
    }
}

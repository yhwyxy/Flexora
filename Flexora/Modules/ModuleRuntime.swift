public final class ModuleRuntime {
    public private(set) var registeredModules: [String: ToolModule] = [:]
    public private(set) var enabledModuleIDs: Set<String> = []
    public private(set) var activeModuleID: String?

    public init() {}

    public var availableModules: [ModuleDescriptor] {
        registeredModules.values
            .map(\.descriptor)
            .filter { enabledModuleIDs.contains($0.id) }
            .sorted { $0.name < $1.name }
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
        }
    }

    @discardableResult
    public func activateModule(withID id: String) -> ToolModule? {
        guard enabledModuleIDs.contains(id), let module = registeredModules[id] else {
            return nil
        }

        module.load()
        activeModuleID = id
        return module
    }
}

public struct ModuleDescriptor: Equatable, Sendable {
    public let id: String
    public let name: String
    public let capabilities: Set<ModuleCapability>

    public init(id: String, name: String, capabilities: Set<ModuleCapability> = []) {
        self.id = id
        self.name = name
        self.capabilities = capabilities
    }
}

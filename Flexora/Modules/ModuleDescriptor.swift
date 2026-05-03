public struct ModuleDescriptor: Equatable, Sendable {
    public let id: String
    public let name: String
    public let summary: String
    public let capabilities: Set<ModuleCapability>

    public init(
        id: String,
        name: String,
        summary: String = "",
        capabilities: Set<ModuleCapability> = []
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.capabilities = capabilities
    }
}

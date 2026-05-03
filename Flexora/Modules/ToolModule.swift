import SwiftUI

public protocol ToolModule: AnyObject {
    var descriptor: ModuleDescriptor { get }
    func load()
    func unload()
    @ViewBuilder func makeWorkspaceView(session: ToolSession) -> AnyView
}

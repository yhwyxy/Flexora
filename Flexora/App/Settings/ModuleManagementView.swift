import SwiftUI

struct ModuleManagementView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ModuleLibraryView(model: model)
    }
}

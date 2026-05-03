import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel.bootstrap()

    var body: some View {
        MainWindowView(model: model)
    }
}

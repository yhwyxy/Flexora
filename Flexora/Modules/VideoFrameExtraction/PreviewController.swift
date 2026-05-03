import Combine
import Foundation

final class PreviewController: ObservableObject {
    @Published var isShowingLargePreview = false

    func toggleLargePreview() {
        isShowingLargePreview.toggle()
    }
}

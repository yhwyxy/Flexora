import Combine
import Foundation

final class ThumbnailBrowserViewModel: ObservableObject {
    @Published var exportSelection: Set<String> = []
}

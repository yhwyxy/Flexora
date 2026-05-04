import Combine
import Foundation

@MainActor
final class PreviewController: ObservableObject {
    enum KeyPress {
        case space
        case escape
        case other

        init(keyCode: UInt16) {
            switch keyCode {
            case 49:
                self = .space
            case 53:
                self = .escape
            default:
                self = .other
            }
        }
    }

    @Published private(set) var isShowingLargePreview = false

    func presentLargePreview() {
        isShowingLargePreview = true
    }

    func dismissLargePreview() {
        isShowingLargePreview = false
    }

    func toggleLargePreview() {
        isShowingLargePreview.toggle()
    }

    func reset() {
        dismissLargePreview()
    }

    @discardableResult
    func handleWorkspaceKeyPress(_ keyPress: KeyPress, hasFocusedCandidate: Bool) -> Bool {
        if isShowingLargePreview {
            return handlePreviewKeyPress(keyPress)
        }

        guard hasFocusedCandidate else {
            return false
        }

        switch keyPress {
        case .space:
            presentLargePreview()
            return true
        case .escape, .other:
            return false
        }
    }

    @discardableResult
    func handlePreviewKeyPress(_ keyPress: KeyPress) -> Bool {
        guard isShowingLargePreview else {
            return false
        }

        switch keyPress {
        case .space, .escape:
            dismissLargePreview()
            return true
        case .other:
            return false
        }
    }
}

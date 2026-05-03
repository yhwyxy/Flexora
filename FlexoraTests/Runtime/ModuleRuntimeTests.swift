import AppKit
import Testing
@testable import Flexora

struct ModuleRuntimeTests {
    @MainActor
    @Test func smoke() {
        let hostingView = NSHostingView(rootView: ContentView())
        hostingView.frame = NSRect(x: 0, y: 0, width: 640, height: 480)
        hostingView.layoutSubtreeIfNeeded()

        let label = findTextField(in: hostingView)

        #expect(label?.stringValue == ContentView.placeholderTitle)
    }

    @MainActor
    private func findTextField(in view: NSView) -> NSTextField? {
        if let textField = view as? NSTextField {
            return textField
        }

        for subview in view.subviews {
            if let match = findTextField(in: subview) {
                return match
            }
        }

        return nil
    }
}

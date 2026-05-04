import Testing
@testable import Flexora

@MainActor
struct PreviewControllerTests {
    @Test func presentsAndDismissesLargePreview() {
        let controller = PreviewController()

        #expect(!controller.isShowingLargePreview)

        controller.presentLargePreview()
        #expect(controller.isShowingLargePreview)

        controller.dismissLargePreview()
        #expect(!controller.isShowingLargePreview)
    }

    @Test func toggleFlipsPreviewPresentationState() {
        let controller = PreviewController()

        controller.toggleLargePreview()
        #expect(controller.isShowingLargePreview)

        controller.toggleLargePreview()
        #expect(!controller.isShowingLargePreview)
    }

    @Test func previewDismissalKeysCloseVisiblePreview() {
        let controller = PreviewController()
        controller.presentLargePreview()

        #expect(controller.handleWorkspaceKeyPress(.space, hasFocusedCandidate: true))
        #expect(!controller.isShowingLargePreview)

        controller.presentLargePreview()
        #expect(controller.handleWorkspaceKeyPress(.escape, hasFocusedCandidate: true))
        #expect(!controller.isShowingLargePreview)
    }

    @Test func workspaceSpaceKeyOpensAndClosesPreviewWhenCandidateIsFocused() {
        let controller = PreviewController()

        #expect(controller.handleWorkspaceKeyPress(.space, hasFocusedCandidate: true))
        #expect(controller.isShowingLargePreview)

        #expect(controller.handleWorkspaceKeyPress(.space, hasFocusedCandidate: true))
        #expect(!controller.isShowingLargePreview)
    }

    @Test func unrelatedKeysDoNotDismissPreview() {
        let controller = PreviewController()
        controller.presentLargePreview()

        #expect(!controller.handleWorkspaceKeyPress(.other, hasFocusedCandidate: true))
        #expect(controller.isShowingLargePreview)
    }

    @Test func dismissalKeysAreIgnoredWhenPreviewIsHidden() {
        let controller = PreviewController()

        #expect(!controller.handleWorkspaceKeyPress(.escape, hasFocusedCandidate: true))
        #expect(!controller.isShowingLargePreview)
    }

    @Test func previewSpaceKeyIsIgnoredWithoutFocusedCandidate() {
        let controller = PreviewController()

        #expect(!controller.handleWorkspaceKeyPress(.space, hasFocusedCandidate: false))
        #expect(!controller.isShowingLargePreview)
    }

    @Test func resetDismissesVisiblePreview() {
        let controller = PreviewController()
        controller.presentLargePreview()

        controller.reset()

        #expect(!controller.isShowingLargePreview)
    }
}

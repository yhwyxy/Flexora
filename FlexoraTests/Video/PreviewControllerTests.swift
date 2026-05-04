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

        #expect(controller.handlePreviewKeyPress(.space))
        #expect(!controller.isShowingLargePreview)

        controller.presentLargePreview()
        #expect(controller.handlePreviewKeyPress(.escape))
        #expect(!controller.isShowingLargePreview)
    }

    @Test func unrelatedKeysDoNotDismissPreview() {
        let controller = PreviewController()
        controller.presentLargePreview()

        #expect(!controller.handlePreviewKeyPress(.other))
        #expect(controller.isShowingLargePreview)
    }

    @Test func dismissalKeysAreIgnoredWhenPreviewIsHidden() {
        let controller = PreviewController()

        #expect(!controller.handlePreviewKeyPress(.space))
        #expect(!controller.handlePreviewKeyPress(.escape))
        #expect(!controller.isShowingLargePreview)
    }
}

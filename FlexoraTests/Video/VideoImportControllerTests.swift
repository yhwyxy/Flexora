import Foundation
import Testing
@testable import Flexora

struct VideoImportControllerTests {
    @Test func supportsMovAndMp4Files() {
        let controller = VideoImportController()

        #expect(controller.isSupportedVideoURL(URL(fileURLWithPath: "/tmp/test.mov")))
        #expect(controller.isSupportedVideoURL(URL(fileURLWithPath: "/tmp/test.mp4")))
        #expect(!controller.isSupportedVideoURL(URL(fileURLWithPath: "/tmp/test.pdf")))
    }
}

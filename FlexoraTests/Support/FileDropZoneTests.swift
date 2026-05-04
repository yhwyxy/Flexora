import Foundation
import Testing
@testable import Flexora

struct FileDropZoneTests {
    @Test func decodesFileURLData() {
        let url = URL(fileURLWithPath: "/tmp/wallpaper.mov")

        let decodedURL = FileDropZone.decodeFileURL(from: url.dataRepresentation)

        #expect(decodedURL == url)
    }

    @Test func returnsNilForInvalidFileURLData() {
        let decodedURL = FileDropZone.decodeFileURL(from: Data("not-a-url".utf8))

        #expect(decodedURL == nil)
    }
}

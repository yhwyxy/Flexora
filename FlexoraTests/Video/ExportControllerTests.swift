import Foundation
import Testing
@testable import Flexora

struct ExportControllerTests {
    @Test func supportsPngJpegAndHeic() {
        #expect(VideoExportFormat.allCases == [.png, .jpeg, .heic])
    }

    @Test func historyStoresCompletedExportEntries() {
        let session = ToolSession(moduleID: "video")
        session.recordExport(fileNames: ["wallpaper-1.heic"])

        #expect(session.history.count == 1)
        #expect(session.history.first?.fileNames == ["wallpaper-1.heic"])
    }

    @Test func heicFailureFallsBackToUserVisibleError() {
        let controller = ExportController()
        let message = controller.userFacingError(for: .heicEncodingUnavailable)

        #expect(message == "HEIC export is unavailable for this file. Choose PNG or JPEG instead.")
    }
}

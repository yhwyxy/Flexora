import Foundation

enum VideoExportFormat: String, CaseIterable, Equatable {
    case png = "PNG"
    case jpeg = "JPEG"
    case heic = "HEIC"
}

enum WallpaperFitMode: String, CaseIterable, Equatable {
    case original = "Original"
    case cropToDesktopAspect = "Crop"
    case fillToDesktopAspect = "Fill"
}

struct VideoExportSettings: Equatable {
    var format: VideoExportFormat = .heic
    var fitMode: WallpaperFitMode = .cropToDesktopAspect
}

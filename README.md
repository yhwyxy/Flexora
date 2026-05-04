# Flexora

A modular macOS tool workbench built with Swift and SwiftUI. Flexora provides a workflow-driven shell where users compose, enable, and run independent tool modules — starting with video frame extraction, and designed to grow with future modules like PDF conversion, audio extraction, and more.

## Features

- **Modular Runtime** — register, enable, disable, and activate tool modules at runtime. Each module is a self-contained unit with its own workspace view.
- **Workflow System** — compose multi-step workflows in the Workshop canvas editor, tag and categorize them, and launch them from the Home page.
- **Video Frame Extraction** — load `.mov` / `.mp4` videos, extract candidate frames via AVFoundation, browse thumbnails horizontally, preview fullscreen with Space, and export as PNG, JPEG, or HEIC.
- **Three-Pane Shell** — Home (workflow launcher with category tags), Workshop (visual workflow editor), Modules (card grid with toggle switches), all in a native `NavigationSplitView` sidebar.

## Requirements

- macOS 15+
- Xcode 16+
- Swift 6.0+

## Getting Started

```bash
# Clone the repository
git clone <repo-url> && cd Flexora

# Open in Xcode
open Flexora.xcodeproj

# Build and run
xcodebuild -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' build

# Run unit tests
xcodebuild -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' test
```

## Project Structure

```
Flexora/
  App/
    AppModel.swift              # Central app state and routing
    AppRoute.swift              # Route enum for navigation
    MainWindowView.swift        # Root window with sidebar
    Home/                       # Home page with workflow cards
    Workshop/                   # Workflow canvas editor
    Modules/                    # Module library cards
    Settings/                   # Settings window
    Sidebar/                    # Sidebar view
    Task/                       # Workflow task execution view
  Modules/
    ModuleRuntime.swift         # Module registry and lifecycle
    ToolModule.swift            # Module protocol
    ToolSession.swift           # Session state per module
    VideoFrameExtraction/       # Video frame extraction module
  Workflows/
    WorkflowStore.swift         # Workflow persistence and categories
    WorkflowDefinition.swift    # Workflow data model
  Support/
    FileDropZone.swift          # Drag-and-drop + click-to-browse
    ImageExportEncoding.swift   # PNG/JPEG/HEIC encoding
    AppLogger.swift             # Unified logging
FlexoraTests/                   # Unit tests
FlexoraUITests/                 # UI tests
```

## Adding a New Module

1. Create a directory under `Flexora/Modules/YourModule/`.
2. Implement the `ToolModule` protocol with a `ModuleDescriptor` and `makeWorkspaceView(session:)`.
3. Register the module in `FlexoraApp.swift` via `runtime.register(module:)`.

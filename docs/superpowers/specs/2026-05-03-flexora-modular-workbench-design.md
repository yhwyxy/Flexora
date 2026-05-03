# Flexora Modular Workbench Design

**Date:** 2026-05-03
**Platform:** macOS
**Stack:** Swift, SwiftUI, AVFoundation, AppKit interop where needed

## Summary

Flexora is a macOS-native modular tool workbench. The product centers on functional modules that can be enabled, disabled, loaded, unloaded, and later composed into larger workflows. The first module is a video frame extraction tool optimized for turning dynamic wallpaper videos into static wallpapers by browsing intelligent frame candidates, previewing them at large size, and exporting selected frames as images.

The first release supports only one active module per session, but the architecture must preserve clear extension points for future multi-module collaboration.

## Product Goals

- Build a reusable modular tool runtime instead of a one-off utility page.
- Ship a first-class video frame extraction module for local video files.
- Provide a macOS-native GUI for import, thumbnail browsing, preview, and export.
- Keep the application responsive while handling high-resolution, including 4K, video input.
- Make future modules such as PDF conversion or audio extraction first-class peers in the same runtime.

## Non-Goals For V1

- Runtime loading of external plugin bundles.
- Multi-module execution or workflow orchestration.
- Video editing, trimming, or timeline-based clip authoring.
- Persisting task history after the app closes.
- Automatically setting exported images as the current macOS wallpaper.
- iOS support.

## Core Architecture

The application is organized around four layers.

### 1. App Shell

The shell owns the main window, module selection entry, settings window, and top-level navigation. It knows which modules are registered and which are currently enabled. It does not implement module-specific business logic.

Responsibilities:

- Create and host the module runtime.
- Present the module selection workspace at startup.
- Open the settings window for module management and global preferences.
- Manage session-level navigation and high-level app state.

### 2. Module Runtime

The runtime manages module registration, activation eligibility, lifecycle, and workspace view creation. Each module is a functional unit, not just a visual fragment.

Each module should expose at least:

- Stable identity: `id`, `name`, `icon`
- Capability description: supported inputs, outputs, and tags
- Lifecycle hooks: `load()`, `unload()`
- Workspace factory: `makeWorkspaceView()`
- Optional future-facing I/O descriptors for later module chaining

V1 supports only one active module session at a time, but runtime contracts should leave room for future module-to-module output handoff.

### 3. Session Workspace

The main window is session-driven rather than home-page-driven. The user chooses a module for the current session, then works inside that module’s workspace.

The session layer owns:

- Current selected module
- Current input resource
- Current module execution state
- Temporary module results
- In-memory history for this app launch

### 4. Module Services

Each module internally separates UI state from processing services. For the video frame extraction module, SwiftUI views remain focused on interaction while background services handle media reading, candidate frame analysis, and export encoding.

## Module Lifecycle

Modules move through these conceptual states:

- `registered`: known to the app runtime
- `loaded`: service instances initialized and ready
- `active`: currently attached to the user’s session
- `unloaded`: released after explicit disable or lifecycle cleanup

Settings-window enable and disable actions are real lifecycle controls:

- Enabling a module makes it eligible to appear in the module chooser.
- Opening a module workspace triggers `load()` if needed.
- Disabling a module hides it from the chooser and triggers `unload()`.
- Unload should release caches, cancel transient work, and detach module resources from the current session.

## Main Window And Settings Structure

### Main Window

The app starts in a module-selection workspace, not a landing page and not a hard-wired module screen. This keeps the product aligned with a modular future even when only one module exists.

Recommended structure:

- Left sidebar for current session context, in-memory history, and returning to module selection
- Main content area for the currently active module workspace

For the video frame extraction module, the workspace should use:

- Top toolbar for import, re-analysis, and export actions
- Large central thumbnail browser as the primary interaction surface
- Secondary inspector-style area for large preview, export selection, and export options

This layout reflects the real task: visually choosing still images, not editing a timeline.

### Settings Window

Settings are separated from the main work area and include at least:

- `Modules`: all registered modules, enabled state, short description, capability tags
- `General`: default export directory, default image format, default wallpaper fit strategy

Disabling a module in settings removes it from the main module selector and initiates unload behavior.

## Video Frame Extraction Module

### Purpose

This module extracts still frames from local videos and helps the user select wallpaper-worthy images by browsing visually distinct frame candidates instead of manually scrubbing timestamps.

### Supported Inputs

- Local video files selected from disk
- Local video files dropped onto the module workspace

Targeted common formats include `MP4` and `MOV`.

### Primary User Flow

1. User selects the video frame extraction module from the module chooser.
2. User imports a local video by drag-and-drop or file picker.
3. The module performs lightweight candidate frame analysis.
4. The user browses generated thumbnails.
5. The user focuses a thumbnail and presses `Space` to open a large preview of that exact frame.
6. The user adds one or more frames to the export list.
7. The user chooses export format and wallpaper fitting options.
8. The module exports selected frames and records the result in this launch’s session history.

### Internal Responsibilities

#### VideoImportController

Handles file drops, file-picking, and basic input validation. It creates the input resource reference for the active session.

#### FrameCandidateService

Generates useful frame candidates after video load. V1 uses scene-change-driven lightweight screening rather than uniform timeline sampling.

Expected behavior:

- Read a cost-controlled set of sampled frames
- Compare adjacent samples for visual difference
- Retain frames that likely represent distinct compositions or visual states
- Avoid flooding the user with near-duplicate thumbnails

This is intentionally pragmatic, not a heavy AI analysis pipeline.

#### ThumbnailBrowserViewModel

Owns the candidate list, current focus, selection state, export list state, and any local sorting or refinement controls.

The primary path is:

- browse thumbnails
- focus a candidate
- preview with `Space`
- add chosen frames to export list

#### PreviewController

Shows a large preview of the currently focused thumbnail frame. `Space` opens a still-image preview of that frame, not video playback.

This is a strict product decision: the tool is for picking still wallpapers, not becoming a general video editor.

#### ExportController

Exports selected frames to a user-selected destination folder with image format and wallpaper adaptation options.

Supported export formats:

- `PNG`
- `JPEG`
- `HEIC`

Supported adaptation strategies:

- Original resolution output
- Crop to desktop aspect ratio
- Fill to desktop aspect ratio

If `HEIC` cannot be produced reliably through native macOS encoding for a given environment or asset path, the UI should expose that failure clearly and keep other formats available.

## State Model

For the video module, the core state flow should be:

- `idle`: no video loaded
- `analyzing`: candidate generation running
- `browsing`: candidate thumbnails available
- `previewing`: large preview open for focused frame
- `exportReady`: one or more frames selected for export
- `exporting`: writing image files
- `completed`: export completed and recorded in session history
- `failed`: recoverable or blocking failure occurred

The shell owns navigation between module chooser and workspace. The module owns its operational state but not app-wide routing.

## Performance Strategy

Responsiveness is a hard requirement, especially for 4K inputs.

The implementation should follow these principles:

- Candidate analysis must run off the main thread.
- Thumbnail generation and large preview generation should use separate caching strategies.
- Export should run as an independent task flow and not freeze the browsing UI.
- UI updates should reflect state snapshots rather than blocking on synchronous media work.
- Re-importing a video should cancel stale analysis work.
- Switching modules should cancel transient module work that no longer matters.
- Unloading a module should release caches and media processing resources.

Where useful, initial frame candidates may appear incrementally rather than waiting for the full set, as long as the UI remains coherent.

## Error Handling

V1 must cover at least these failure classes:

- Unsupported or corrupted video file
- Readable video but no usable frames can be extracted
- Candidate analysis interrupted or fails
- Destination directory unavailable or unwritable
- Export format encoding failure, especially `HEIC`

User-facing presentation should be tiered:

- Recoverable issues: inline banner or contextual error with retry affordance
- Blocking issues: explicit modal or alert
- Developer diagnostics: structured logs without leaking implementation details into user-facing copy

## History Model

History is session-scoped only.

- Export results should remain visible for the current app launch.
- Users can inspect earlier exports from the current session.
- History is cleared when the app closes.

This avoids introducing persistence infrastructure in V1 while still supporting practical repeat-export and review behavior.

## Testing Strategy

Testing should cover three layers.

### 1. Module Runtime Tests

Validate:

- Registered and enabled modules appear in the chooser
- Disabled modules disappear from the chooser
- Load and unload lifecycle transitions occur correctly
- Session state resets or detaches correctly when switching modules

### 2. Video Module Processing Tests

Validate:

- `MP4` and `MOV` inputs are accepted when valid
- Candidate generation returns useful frames rather than empty output for supported inputs
- Focused candidates produce a large preview
- Selected frames export successfully as `PNG`, `JPEG`, and `HEIC`
- Wallpaper adaptation modes transform output as expected

Boundary cases to include:

- short videos
- 4K videos
- low-resolution videos
- invalid or unreadable files

### 3. UI Interaction Tests

Validate:

- drag-and-drop import path
- file-picker import path
- `Space` opens the current focused frame preview
- multi-selection and export list behavior
- export failure feedback
- settings-based enable and disable of modules

## Release Acceptance Criteria

V1 is complete when all of the following are true:

- A macOS app can be built and launched successfully.
- The app presents a modular runtime with a module selection entry flow.
- Settings can enable and disable modules with real lifecycle behavior.
- The video frame extraction module accepts local files via picker or drag-and-drop.
- The module generates visually distinct candidate thumbnails for supported inputs.
- The user can inspect the currently focused frame in a large still preview with `Space`.
- The user can select multiple frames for export.
- The module exports valid `PNG`, `JPEG`, or `HEIC` image files.
- Wallpaper-fit export options are available.
- The UI remains responsive while working with 4K video.
- Session history is available until app exit.

## Future Extension Points

The architecture should preserve space for:

- richer module capability metadata
- standard module output descriptors
- module-to-module handoff of produced files
- eventual workflow composition across multiple modules
- optional migration to external plugin loading later

These are extension points only and must not add delivery risk to V1.

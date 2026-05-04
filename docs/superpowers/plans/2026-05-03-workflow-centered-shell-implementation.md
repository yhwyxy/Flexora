# Workflow-Centered Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current module-first shell with a workflow-centered macOS app shell, add Home / Workshop / Modules navigation, and fix the current video export and preview regressions while preserving the existing module runtime.

**Architecture:** Keep `ModuleRuntime` as the capability registry and lifecycle boundary, but introduce workflow records plus a `WorkflowStore` as the app’s primary runnable state. The app shell routes by `workflowID`, Home lists workflows, Workshop edits workflows, Modules manages enablement, and the existing video workspace is hosted from a single-module task page. Video export and preview are then tightened inside that task-hosted module UI.

**Tech Stack:** Swift, SwiftUI, Swift Testing, AVFoundation, AppKit interop

---

### Task 1: Add Workflow Domain Types And Store

**Files:**
- Create: `Flexora/Workflows/WorkflowSource.swift`
- Create: `Flexora/Workflows/WorkflowTagRecord.swift`
- Create: `Flexora/Workflows/WorkflowNode.swift`
- Create: `Flexora/Workflows/WorkflowConnection.swift`
- Create: `Flexora/Workflows/WorkflowRecord.swift`
- Create: `Flexora/Workflows/WorkflowAvailability.swift`
- Create: `Flexora/Workflows/WorkflowLibrary.swift`
- Create: `Flexora/Workflows/WorkflowStore.swift`
- Create: `FlexoraTests/Workflow/WorkflowStoreTests.swift`
- Modify: `Flexora/Modules/ModuleDescriptor.swift`
- Modify: `Flexora/Modules/VideoFrameExtraction/VideoFrameExtractionModule.swift`
- Modify: `FlexoraTests/Runtime/ModuleRuntimeTests.swift`

- [ ] **Step 1: Write the failing workflow store tests**

```swift
import Testing
import SwiftUI
@testable import Flexora

@MainActor
struct WorkflowStoreTests {
    @Test func syncDefaultsCreatesOneWorkflowPerEnabledModule() {
        let runtime = ModuleRuntime()
        runtime.register(module: WorkflowTestModule(id: "video", name: "Video Frame Extraction", summary: "Extract still wallpaper frames"))
        runtime.setModuleEnabled("video", isEnabled: true)

        let store = WorkflowStore()
        store.syncDefaults(with: runtime)

        #expect(store.workflows.count == 1)
        #expect(store.workflows[0].source == .default)
        #expect(store.workflows[0].entryModuleID == "video")
        #expect(store.workflows[0].requiredModuleIDs == ["video"])
    }

    @Test func syncDefaultsDoesNotDuplicateExistingDefaultWorkflow() {
        let runtime = ModuleRuntime()
        runtime.register(module: WorkflowTestModule(id: "video", name: "Video Frame Extraction", summary: "Extract still wallpaper frames"))
        runtime.setModuleEnabled("video", isEnabled: true)

        let store = WorkflowStore()
        store.syncDefaults(with: runtime)
        store.syncDefaults(with: runtime)

        #expect(store.workflows.count == 1)
    }

    @Test func disabledModuleLeavesWorkflowVisibleButUnavailable() throws {
        let runtime = ModuleRuntime()
        runtime.register(module: WorkflowTestModule(id: "video", name: "Video Frame Extraction", summary: "Extract still wallpaper frames"))
        runtime.setModuleEnabled("video", isEnabled: true)

        let store = WorkflowStore()
        store.syncDefaults(with: runtime)
        let workflow = try #require(store.workflows.first)

        runtime.setModuleEnabled("video", isEnabled: false)

        let availability = store.availability(for: workflow, runtime: runtime)
        #expect(!availability.isAvailable)
        #expect(availability.missingModuleIDs == ["video"])
    }

    @Test func libraryQueryFiltersAndGroupsByTag() {
        let runtime = ModuleRuntime()
        runtime.register(module: WorkflowTestModule(id: "video", name: "Video Frame Extraction", summary: "Extract still wallpaper frames"))
        runtime.register(module: WorkflowTestModule(id: "audio", name: "Audio Extraction", summary: "Extract audio tracks"))
        runtime.setModuleEnabled("video", isEnabled: true)
        runtime.setModuleEnabled("audio", isEnabled: true)

        let store = WorkflowStore()
        store.syncDefaults(with: runtime)

        let custom = WorkflowRecord(
            name: "Wallpaper Batch",
            description: "Video frames plus audio notes",
            source: .custom,
            entryModuleID: "video",
            graph: WorkflowGraph(
                nodes: [
                    WorkflowNode(moduleID: "video", title: "Video Frames", position: .init(x: 120, y: 160))
                ],
                connections: []
            ),
            tagIDs: []
        )
        store.save(custom)
        let tag = store.ensureTag(named: "Wallpaper")
        store.assignTags([tag.id], to: custom.id)

        let sections = store.librarySections(
            filter: .tag(tag.id),
            runtime: runtime
        )

        #expect(sections.count == 1)
        #expect(sections[0].title == "Wallpaper")
        #expect(sections[0].workflows.map(\.name) == ["Wallpaper Batch"])
    }
}

private final class WorkflowTestModule: ToolModule {
    let descriptor: ModuleDescriptor

    init(id: String, name: String, summary: String) {
        descriptor = ModuleDescriptor(id: id, name: name, summary: summary, capabilities: [])
    }

    func load() {}
    func unload() {}

    func makeWorkspaceView(session: ToolSession) -> AnyView {
        AnyView(EmptyView())
    }
}
```

- [ ] **Step 2: Run the workflow store tests to verify they fail**

Run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' -only-testing:FlexoraTests/WorkflowStoreTests test
```

Expected: `FAIL` because `WorkflowStore`, `WorkflowRecord`, `WorkflowGraph`, and the new `ModuleDescriptor` initializer do not exist yet.

- [ ] **Step 3: Implement the workflow domain types and store**

Write `Flexora/Modules/ModuleDescriptor.swift`:

```swift
public struct ModuleDescriptor: Equatable, Sendable {
    public let id: String
    public let name: String
    public let summary: String
    public let capabilities: Set<ModuleCapability>

    public init(
        id: String,
        name: String,
        summary: String,
        capabilities: Set<ModuleCapability> = []
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.capabilities = capabilities
    }
}
```

Write `Flexora/Workflows/WorkflowSource.swift`:

```swift
import Foundation

enum WorkflowSource: String, Codable, Equatable, Sendable {
    case `default`
    case custom
}
```

Write `Flexora/Workflows/WorkflowTagRecord.swift`:

```swift
import Foundation

struct WorkflowTagRecord: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
```

Write `Flexora/Workflows/WorkflowNode.swift`:

```swift
import CoreGraphics
import Foundation

struct WorkflowNode: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    var moduleID: String
    var title: String
    var position: CGPoint

    init(id: UUID = UUID(), moduleID: String, title: String, position: CGPoint) {
        self.id = id
        self.moduleID = moduleID
        self.title = title
        self.position = position
    }
}
```

Write `Flexora/Workflows/WorkflowConnection.swift`:

```swift
import Foundation

struct WorkflowConnection: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    var fromNodeID: WorkflowNode.ID
    var toNodeID: WorkflowNode.ID

    init(id: UUID = UUID(), fromNodeID: WorkflowNode.ID, toNodeID: WorkflowNode.ID) {
        self.id = id
        self.fromNodeID = fromNodeID
        self.toNodeID = toNodeID
    }
}

struct WorkflowGraph: Equatable, Codable, Sendable {
    var nodes: [WorkflowNode]
    var connections: [WorkflowConnection]
}
```

Write `Flexora/Workflows/WorkflowRecord.swift`:

```swift
import Foundation

struct WorkflowRecord: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    var name: String
    var description: String
    var source: WorkflowSource
    var entryModuleID: String?
    var graph: WorkflowGraph
    var tagIDs: [WorkflowTagRecord.ID]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        source: WorkflowSource,
        entryModuleID: String?,
        graph: WorkflowGraph,
        tagIDs: [WorkflowTagRecord.ID],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.source = source
        self.entryModuleID = entryModuleID
        self.graph = graph
        self.tagIDs = tagIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var requiredModuleIDs: [String] {
        Array(Set(graph.nodes.map(\.moduleID))).sorted()
    }

    static func defaultWorkflow(for descriptor: ModuleDescriptor) -> WorkflowRecord {
        WorkflowRecord(
            name: descriptor.name,
            description: descriptor.summary,
            source: .default,
            entryModuleID: descriptor.id,
            graph: WorkflowGraph(
                nodes: [
                    WorkflowNode(
                        moduleID: descriptor.id,
                        title: descriptor.name,
                        position: CGPoint(x: 180, y: 180)
                    )
                ],
                connections: []
            ),
            tagIDs: []
        )
    }
}
```

Write `Flexora/Workflows/WorkflowAvailability.swift`:

```swift
import Foundation

struct WorkflowAvailability: Equatable, Sendable {
    let workflowID: WorkflowRecord.ID
    let isAvailable: Bool
    let missingModuleIDs: [String]
}
```

Write `Flexora/Workflows/WorkflowLibrary.swift`:

```swift
import Foundation

enum WorkflowLibraryFilter: Equatable, Sendable {
    case all
    case source(WorkflowSource)
    case tag(WorkflowTagRecord.ID)
}

struct WorkflowLibrarySection: Equatable, Sendable {
    let title: String
    let workflows: [WorkflowRecord]
}
```

Write `Flexora/Workflows/WorkflowStore.swift`:

```swift
import Foundation

@MainActor
final class WorkflowStore: ObservableObject {
    @Published private(set) var workflows: [WorkflowRecord] = []
    @Published private(set) var tags: [WorkflowTagRecord] = []

    func syncDefaults(with runtime: ModuleRuntime) {
        for descriptor in runtime.allModules where runtime.isModuleEnabled(descriptor.id) {
            guard !workflows.contains(where: { $0.source == .default && $0.entryModuleID == descriptor.id }) else {
                continue
            }

            workflows.append(.defaultWorkflow(for: descriptor))
        }

        workflows.sort { $0.updatedAt > $1.updatedAt }
    }

    func save(_ workflow: WorkflowRecord) {
        if let index = workflows.firstIndex(where: { $0.id == workflow.id }) {
            workflows[index] = workflow
        } else {
            workflows.insert(workflow, at: 0)
        }
    }

    func workflow(id: WorkflowRecord.ID) -> WorkflowRecord? {
        workflows.first(where: { $0.id == id })
    }

    @discardableResult
    func ensureTag(named name: String) -> WorkflowTagRecord {
        if let existing = tags.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
            return existing
        }

        let record = WorkflowTagRecord(name: name)
        tags.append(record)
        tags.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return record
    }

    func assignTags(_ tagIDs: [WorkflowTagRecord.ID], to workflowID: WorkflowRecord.ID) {
        guard let index = workflows.firstIndex(where: { $0.id == workflowID }) else {
            return
        }

        workflows[index].tagIDs = Array(Set(tagIDs))
        workflows[index].updatedAt = Date()
    }

    func availability(for workflow: WorkflowRecord, runtime: ModuleRuntime) -> WorkflowAvailability {
        let missing = workflow.requiredModuleIDs.filter { !runtime.isModuleEnabled($0) }
        return WorkflowAvailability(
            workflowID: workflow.id,
            isAvailable: missing.isEmpty,
            missingModuleIDs: missing
        )
    }

    func librarySections(
        filter: WorkflowLibraryFilter,
        runtime: ModuleRuntime
    ) -> [WorkflowLibrarySection] {
        let filtered = workflows.filter { workflow in
            switch filter {
            case .all:
                return true
            case let .source(source):
                return workflow.source == source
            case let .tag(tagID):
                return workflow.tagIDs.contains(tagID)
            }
        }

        if case let .tag(tagID) = filter, let tag = tags.first(where: { $0.id == tagID }) {
            return [WorkflowLibrarySection(title: tag.name, workflows: filtered)]
        }

        let grouped = Dictionary(grouping: filtered) { workflow -> String in
            if workflow.tagIDs.isEmpty {
                return "Untagged"
            }

            let names = tags
                .filter { workflow.tagIDs.contains($0.id) }
                .map(\.name)
                .sorted()
            return names.first ?? "Untagged"
        }

        return grouped.keys.sorted().map { key in
            WorkflowLibrarySection(
                title: key,
                workflows: grouped[key, default: []].sorted { $0.name < $1.name }
            )
        }
    }
}
```

Update the `ModuleRuntimeTests` helper initializer in `FlexoraTests/Runtime/ModuleRuntimeTests.swift`:

```swift
    init(id: String, name: String? = nil) {
        descriptor = ModuleDescriptor(
            id: id,
            name: name ?? id.capitalized,
            summary: "\(name ?? id.capitalized) summary",
            capabilities: []
        )
    }
```

Update `Flexora/Modules/VideoFrameExtraction/VideoFrameExtractionModule.swift`:

```swift
import SwiftUI

final class VideoFrameExtractionModule: ToolModule {
    let descriptor = ModuleDescriptor(
        id: "video-frame-extraction",
        name: "Video Frame Extraction",
        summary: "Extract still wallpaper frames from local videos.",
        capabilities: [.workspace]
    )

    func load() {}
    func unload() {}

    func makeWorkspaceView(session: ToolSession) -> AnyView {
        let importController: VideoImportController
        let browserModel: ThumbnailBrowserViewModel

        if ProcessInfo.processInfo.arguments.contains("-flexora-ui-sample-candidates") {
            importController = VideoImportController(
                importedVideoURL: URL(fileURLWithPath: "/tmp/sample-wallpaper.mov")
            )
            browserModel = ThumbnailBrowserViewModel()
            browserModel.loadCandidates(sampleCandidates)
            if let first = sampleCandidates.first {
                browserModel.toggleSelection(for: first)
            }
        } else {
            importController = VideoImportController()
            browserModel = ThumbnailBrowserViewModel()
        }

        return AnyView(
            VideoFrameExtractionWorkspaceView(
                session: session,
                importController: importController,
                browserModel: browserModel
            )
        )
    }
}
```

- [ ] **Step 4: Run the workflow store tests again**

Run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' -only-testing:FlexoraTests/WorkflowStoreTests test
```

Expected: `PASS` for all `WorkflowStoreTests`.

- [ ] **Step 5: Commit the workflow foundation**

```bash
git add Flexora/Modules/ModuleDescriptor.swift Flexora/Modules/VideoFrameExtraction/VideoFrameExtractionModule.swift Flexora/Workflows FlexoraTests/Workflow/WorkflowStoreTests.swift FlexoraTests/Runtime/ModuleRuntimeTests.swift
git commit -m "feat: add workflow domain foundation"
```

### Task 2: Migrate App Routing And AppModel To Workflow-Centered Navigation

**Files:**
- Modify: `Flexora/App/AppRoute.swift`
- Modify: `Flexora/App/AppModel.swift`
- Modify: `FlexoraTests/App/ToolSessionTests.swift`

- [ ] **Step 1: Rewrite the AppModel tests to describe workflow-driven routes**

```swift
import Testing
import SwiftUI
@testable import Flexora

@MainActor
struct ToolSessionTests {
    @Test func openWorkflowRoutesToTaskPage() {
        let runtime = ModuleRuntime()
        runtime.register(module: TestAppModule(id: "video", summary: "Video frames"))
        runtime.setModuleEnabled("video", isEnabled: true)

        let store = WorkflowStore()
        store.syncDefaults(with: runtime)
        let workflow = try! #require(store.workflows.first)

        let model = AppModel(runtime: runtime, workflowStore: store)
        model.openWorkflow(workflow.id)

        #expect(model.route == .task(workflowID: workflow.id))
        #expect(model.activeSession?.moduleID == "video")
    }

    @Test func editWorkflowRoutesToEditorPage() {
        let runtime = ModuleRuntime()
        runtime.register(module: TestAppModule(id: "video", summary: "Video frames"))
        runtime.setModuleEnabled("video", isEnabled: true)

        let store = WorkflowStore()
        store.syncDefaults(with: runtime)
        let workflow = try! #require(store.workflows.first)

        let model = AppModel(runtime: runtime, workflowStore: store)
        model.editWorkflow(workflow.id)

        #expect(model.route == .workflowEditor(workflowID: workflow.id))
    }

    @Test func openingUnknownWorkflowKeepsHomeRoute() {
        let model = AppModel(runtime: ModuleRuntime(), workflowStore: WorkflowStore())

        model.route = .home
        model.openWorkflow(UUID())

        #expect(model.route == .home)
        #expect(model.activeSession == nil)
    }

    @Test func disablingReferencedModuleKeepsWorkflowButClearsActiveSession() {
        let runtime = ModuleRuntime()
        runtime.register(module: TestAppModule(id: "video", summary: "Video frames"))
        runtime.setModuleEnabled("video", isEnabled: true)

        let store = WorkflowStore()
        store.syncDefaults(with: runtime)
        let workflow = try! #require(store.workflows.first)

        let model = AppModel(runtime: runtime, workflowStore: store)
        model.openWorkflow(workflow.id)
        runtime.setModuleEnabled("video", isEnabled: false)
        model.syncStateFromRuntime()

        #expect(model.route == .task(workflowID: workflow.id))
        #expect(model.activeSession == nil)
        #expect(!store.availability(for: workflow, runtime: runtime).isAvailable)
    }
}

private final class TestAppModule: ToolModule {
    let descriptor: ModuleDescriptor

    init(id: String, summary: String) {
        descriptor = ModuleDescriptor(id: id, name: id.capitalized, summary: summary, capabilities: [])
    }

    func load() {}
    func unload() {}

    func makeWorkspaceView(session: ToolSession) -> AnyView {
        AnyView(EmptyView())
    }
}
```

- [ ] **Step 2: Run the AppModel tests to verify they fail**

Run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' -only-testing:FlexoraTests/ToolSessionTests test
```

Expected: `FAIL` because `AppRoute.home`, `AppRoute.task`, `AppRoute.workflowEditor`, and the new `AppModel` initializer and methods do not exist yet.

- [ ] **Step 3: Implement workflow-first routing in `AppRoute` and `AppModel`**

Write `Flexora/App/AppRoute.swift`:

```swift
import Foundation

public enum AppRoute: Equatable {
    case home
    case workshop
    case modules
    case task(workflowID: WorkflowRecord.ID)
    case workflowEditor(workflowID: WorkflowRecord.ID)
}
```

Write `Flexora/App/AppModel.swift`:

```swift
import Combine
import SwiftUI

@MainActor
public final class AppModel: ObservableObject {
    public let runtime: ModuleRuntime
    public let workflowStore: WorkflowStore

    @Published public var route: AppRoute
    @Published public private(set) var activeSession: ToolSession?

    private var runtimeCancellable: AnyCancellable?

    public init(
        runtime: ModuleRuntime,
        workflowStore: WorkflowStore,
        route: AppRoute = .home
    ) {
        self.runtime = runtime
        self.workflowStore = workflowStore
        self.route = route

        workflowStore.syncDefaults(with: runtime)
        runtimeCancellable = runtime.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    public func showHome() {
        route = .home
    }

    public func showWorkshop() {
        route = .workshop
    }

    public func showModules() {
        route = .modules
    }

    public func openWorkflow(_ workflowID: WorkflowRecord.ID) {
        guard let workflow = workflowStore.workflow(id: workflowID) else {
            route = .home
            activeSession = nil
            return
        }

        activateSingleModuleSessionIfNeeded(for: workflow)
        route = .task(workflowID: workflowID)
    }

    public func editWorkflow(_ workflowID: WorkflowRecord.ID) {
        guard workflowStore.workflow(id: workflowID) != nil else {
            route = .home
            return
        }

        route = .workflowEditor(workflowID: workflowID)
    }

    public func setModuleEnabled(_ id: String, isEnabled: Bool) {
        runtime.setModuleEnabled(id, isEnabled: isEnabled)
        workflowStore.syncDefaults(with: runtime)

        if activeSession?.moduleID == id, !isEnabled {
            activeSession = nil
        }
    }

    public func syncStateFromRuntime() {
        workflowStore.syncDefaults(with: runtime)

        if let session = activeSession, !runtime.isModuleEnabled(session.moduleID) {
            activeSession = nil
        }
    }

    private func activateSingleModuleSessionIfNeeded(for workflow: WorkflowRecord) {
        guard
            workflow.graph.nodes.count == 1,
            let moduleID = workflow.entryModuleID,
            runtime.activateModule(withID: moduleID) != nil
        else {
            activeSession = nil
            return
        }

        if activeSession?.moduleID != moduleID {
            activeSession = ToolSession(moduleID: moduleID)
        }
    }
}
```

- [ ] **Step 4: Run the AppModel tests again**

Run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' -only-testing:FlexoraTests/ToolSessionTests test
```

Expected: `PASS` for the updated `ToolSessionTests`.

- [ ] **Step 5: Commit the workflow-aware app model**

```bash
git add Flexora/App/AppRoute.swift Flexora/App/AppModel.swift FlexoraTests/App/ToolSessionTests.swift
git commit -m "feat: route app shell by workflow"
```

### Task 3: Replace The Old Module Chooser With Home And Modules Surfaces

**Files:**
- Create: `Flexora/App/Sidebar/AppSidebarView.swift`
- Create: `Flexora/App/Home/HomeView.swift`
- Create: `Flexora/App/Home/WorkflowCardView.swift`
- Create: `Flexora/App/Modules/ModuleLibraryView.swift`
- Create: `Flexora/App/Modules/ModuleCardView.swift`
- Modify: `Flexora/App/MainWindowView.swift`
- Modify: `Flexora/FlexoraApp.swift`
- Delete: `Flexora/App/Selection/ModuleSelectionView.swift`
- Modify: `Flexora/App/Settings/SettingsView.swift`

- [ ] **Step 1: Build a failing compile target around the new shell files**

Add the new view declarations and switch `MainWindowView` references so the build fails until the new views exist:

```swift
// MainWindowView.swift temporary target shape
switch model.route {
case .home:
    HomeView(model: model)
case .modules:
    ModuleLibraryView(model: model)
default:
    Text("Stub")
}
```

- [ ] **Step 2: Run a build to confirm the shell does not compile yet**

Run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' DEVELOPMENT_TEAM='' build-for-testing
```

Expected: `FAIL` because `HomeView`, `ModuleLibraryView`, and `AppSidebarView` are not defined.

- [ ] **Step 3: Implement the Home and Modules shell views**

Write `Flexora/App/Sidebar/AppSidebarView.swift`:

```swift
import SwiftUI

struct AppSidebarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List(selection: .constant(nil)) {
            Button("Home") { model.showHome() }
                .buttonStyle(.plain)
            Button("Workshop") { model.showWorkshop() }
                .buttonStyle(.plain)
            Button("Modules") { model.showModules() }
                .buttonStyle(.plain)
        }
        .navigationTitle("Flexora")
    }
}
```

Write `Flexora/App/Home/WorkflowCardView.swift`:

```swift
import SwiftUI

struct WorkflowCardView: View {
    let workflow: WorkflowRecord
    let availability: WorkflowAvailability
    let tagNames: [String]
    let onOpen: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(workflow.name)
                        .font(.headline)
                    Text(workflow.source == .default ? "Default Workflow" : "Custom Workflow")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(availability.isAvailable ? "Ready" : "Unavailable")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
            }

            if !workflow.description.isEmpty {
                Text(workflow.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !tagNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tagNames, id: \.self) { tagName in
                            Text(tagName)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.12), in: Capsule())
                        }
                    }
                }
            }

            if !availability.isAvailable {
                Text("Missing modules: \(availability.missingModuleIDs.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Open", action: onOpen)
                    .disabled(!availability.isAvailable)
                Button("Edit", action: onEdit)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .opacity(availability.isAvailable ? 1 : 0.55)
    }
}
```

Write `Flexora/App/Home/HomeView.swift`:

```swift
import SwiftUI

struct HomeView: View {
    @ObservedObject var model: AppModel
    @State private var selectedFilter: WorkflowLibraryFilter = .all

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                filterBar

                ForEach(sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(section.title)
                            .font(.title3.weight(.semibold))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 16)], spacing: 16) {
                            ForEach(section.workflows) { workflow in
                                WorkflowCardView(
                                    workflow: workflow,
                                    availability: model.workflowStore.availability(for: workflow, runtime: model.runtime),
                                    tagNames: tagNames(for: workflow),
                                    onOpen: { model.openWorkflow(workflow.id) },
                                    onEdit: { model.editWorkflow(workflow.id) }
                                )
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var sections: [WorkflowLibrarySection] {
        model.workflowStore.librarySections(filter: selectedFilter, runtime: model.runtime)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button("All") { selectedFilter = .all }
                Button("Default") { selectedFilter = .source(.default) }
                Button("Custom") { selectedFilter = .source(.custom) }
                ForEach(model.workflowStore.tags, id: \.id) { tag in
                    Button(tag.name) { selectedFilter = .tag(tag.id) }
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private func tagNames(for workflow: WorkflowRecord) -> [String] {
        model.workflowStore.tags
            .filter { workflow.tagIDs.contains($0.id) }
            .map(\.name)
            .sorted()
    }
}
```

Write `Flexora/App/Modules/ModuleCardView.swift`:

```swift
import SwiftUI

struct ModuleCardView: View {
    let module: ModuleDescriptor
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(module.name)
                        .font(.headline)
                    Text(module.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(get: { isEnabled }, set: onToggle))
                    .labelsHidden()
            }

            Text(module.id)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
```

Write `Flexora/App/Modules/ModuleLibraryView.swift`:

```swift
import SwiftUI

struct ModuleLibraryView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                ForEach(model.runtime.allModules, id: \.id) { module in
                    ModuleCardView(
                        module: module,
                        isEnabled: model.runtime.isModuleEnabled(module.id),
                        onToggle: { model.setModuleEnabled(module.id, isEnabled: $0) }
                    )
                }
            }
            .padding(24)
        }
    }
}
```

Write `Flexora/App/MainWindowView.swift`:

```swift
import SwiftUI

struct MainWindowView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationSplitView {
            AppSidebarView(model: model)
        } detail: {
            switch model.route {
            case .home:
                HomeView(model: model)
            case .modules:
                ModuleLibraryView(model: model)
            case .workshop, .task, .workflowEditor:
                Text("Next task wires these routes.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
```

Update `Flexora/FlexoraApp.swift`:

```swift
import SwiftUI

@main
struct FlexoraApp: App {
    @StateObject private var model = makeModel()

    var body: some Scene {
        WindowGroup {
            MainWindowView(model: model)
        }
        Settings {
            SettingsView(model: model)
        }
    }

    private static func makeModel() -> AppModel {
        let runtime = ModuleRuntime()
        let workflowStore = WorkflowStore()
        let videoModule = VideoFrameExtractionModule()

        runtime.register(module: videoModule)
        runtime.setModuleEnabled(videoModule.descriptor.id, isEnabled: true)
        workflowStore.syncDefaults(with: runtime)

        return AppModel(runtime: runtime, workflowStore: workflowStore)
    }
}
```

Update `Flexora/App/Settings/SettingsView.swift` to keep a small transitional settings surface:

```swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.title.bold())
            Text("General settings will live here. Module enablement now lives in the Modules page.")
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 420, minHeight: 220)
        .padding(24)
    }
}
```

- [ ] **Step 4: Run a build to verify the new shell compiles**

Run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' DEVELOPMENT_TEAM='' build-for-testing
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5: Commit the Home and Modules shell**

```bash
git add Flexora/App/Sidebar/AppSidebarView.swift Flexora/App/Home Flexora/App/Modules Flexora/App/MainWindowView.swift Flexora/FlexoraApp.swift Flexora/App/Settings/SettingsView.swift
git rm Flexora/App/Selection/ModuleSelectionView.swift
git commit -m "feat: add workflow home and module library views"
```

### Task 4: Add Workshop And Task Pages For Workflow Execution And Repair

**Files:**
- Create: `Flexora/App/Task/WorkflowTaskView.swift`
- Create: `Flexora/App/Workshop/WorkflowWorkshopView.swift`
- Create: `Flexora/App/Workshop/WorkflowCanvasView.swift`
- Create: `Flexora/App/Workshop/WorkflowInspectorView.swift`
- Modify: `Flexora/App/MainWindowView.swift`

- [ ] **Step 1: Add a failing integration point for task and editor routes**

Update the `MainWindowView` route switch to point at the final route destinations before those views exist:

```swift
case let .task(workflowID):
    WorkflowTaskView(model: model, workflowID: workflowID)
case .workshop:
    WorkflowWorkshopView(model: model, workflowID: nil)
case let .workflowEditor(workflowID):
    WorkflowWorkshopView(model: model, workflowID: workflowID)
```

- [ ] **Step 2: Run a build to verify the task/editor surfaces are still missing**

Run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' DEVELOPMENT_TEAM='' build-for-testing
```

Expected: `FAIL` because `WorkflowTaskView` and `WorkflowWorkshopView` do not exist yet.

- [ ] **Step 3: Implement the task page and workshop skeleton**

Write `Flexora/App/Task/WorkflowTaskView.swift`:

```swift
import SwiftUI

struct WorkflowTaskView: View {
    @ObservedObject var model: AppModel
    let workflowID: WorkflowRecord.ID

    var body: some View {
        Group {
            if let workflow = model.workflowStore.workflow(id: workflowID) {
                let availability = model.workflowStore.availability(for: workflow, runtime: model.runtime)

                if !availability.isAvailable {
                    unavailableSurface(workflow: workflow, availability: availability)
                } else if
                    workflow.graph.nodes.count == 1,
                    let moduleID = workflow.entryModuleID,
                    let session = model.activeSession,
                    session.moduleID == moduleID,
                    let module = model.runtime.module(withID: moduleID)
                {
                    module.makeWorkspaceView(session: session)
                } else {
                    graphSummarySurface(for: workflow)
                }
            } else {
                ContentUnavailableView("Workflow Missing", systemImage: "square.slash")
            }
        }
    }

    private func unavailableSurface(workflow: WorkflowRecord, availability: WorkflowAvailability) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(workflow.name)
                .font(.largeTitle.bold())
            Text("This workflow cannot run because these modules are disabled: \(availability.missingModuleIDs.joined(separator: ", ")).")
                .foregroundStyle(.secondary)
            Button("Edit Workflow") {
                model.editWorkflow(workflow.id)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }

    private func graphSummarySurface(for workflow: WorkflowRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(workflow.name)
                .font(.largeTitle.bold())
            Text("Execution summary")
                .font(.title3.weight(.semibold))
            ForEach(workflow.graph.nodes) { node in
                Text("• \(node.title) (\(node.moduleID))")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}
```

Write `Flexora/App/Workshop/WorkflowCanvasView.swift`:

```swift
import SwiftUI

struct WorkflowCanvasView: View {
    let workflow: WorkflowRecord
    let unavailableModuleIDs: Set<String>

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.secondary.opacity(0.06))

            ForEach(workflow.graph.nodes) { node in
                VStack(alignment: .leading, spacing: 6) {
                    Text(node.title)
                        .font(.headline)
                    Text(node.moduleID)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if unavailableModuleIDs.contains(node.moduleID) {
                        Text("Unavailable")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
                .padding(14)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .position(x: node.position.x, y: node.position.y)
                .opacity(unavailableModuleIDs.contains(node.moduleID) ? 0.55 : 1)
            }
        }
    }
}
```

Write `Flexora/App/Workshop/WorkflowInspectorView.swift`:

```swift
import SwiftUI

struct WorkflowInspectorView: View {
    @Binding var workflow: WorkflowRecord
    @ObservedObject var store: WorkflowStore
    @State private var newTagName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Workflow Name", text: $workflow.name)
            TextField("Description", text: $workflow.description, axis: .vertical)

            Text("Tags")
                .font(.headline)

            ForEach(store.tags, id: \.id) { tag in
                Toggle(
                    tag.name,
                    isOn: Binding(
                        get: { workflow.tagIDs.contains(tag.id) },
                        set: { isSelected in
                            if isSelected {
                                workflow.tagIDs.append(tag.id)
                            } else {
                                workflow.tagIDs.removeAll { $0 == tag.id }
                            }
                        }
                    )
                )
            }

            HStack {
                TextField("New Tag", text: $newTagName)
                Button("Add") {
                    let tag = store.ensureTag(named: newTagName.trimmingCharacters(in: .whitespacesAndNewlines))
                    if !workflow.tagIDs.contains(tag.id) {
                        workflow.tagIDs.append(tag.id)
                    }
                    newTagName = ""
                }
                .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Spacer()
        }
        .padding(18)
    }
}
```

Write `Flexora/App/Workshop/WorkflowWorkshopView.swift`:

```swift
import SwiftUI

struct WorkflowWorkshopView: View {
    @ObservedObject var model: AppModel
    let workflowID: WorkflowRecord.ID?

    @State private var draft = WorkflowRecord(
        name: "New Workflow",
        description: "",
        source: .custom,
        entryModuleID: nil,
        graph: WorkflowGraph(nodes: [], connections: []),
        tagIDs: []
    )

    var body: some View {
        HStack(spacing: 18) {
            modulePalette
                .frame(width: 220)

            WorkflowCanvasView(
                workflow: currentWorkflow,
                unavailableModuleIDs: Set(
                    model.workflowStore.availability(for: currentWorkflow, runtime: model.runtime).missingModuleIDs
                )
            )

            WorkflowInspectorView(
                workflow: bindingWorkflow,
                store: model.workflowStore
            )
            .frame(width: 260)
        }
        .padding(24)
        .toolbar {
            Button("Save") {
                model.workflowStore.save(currentWorkflow)
                model.showHome()
            }
        }
        .onAppear {
            if let workflowID, let existing = model.workflowStore.workflow(id: workflowID) {
                draft = existing
            }
        }
    }

    private var modulePalette: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Modules")
                .font(.headline)
            ForEach(model.runtime.allModules, id: \.id) { descriptor in
                Button(descriptor.name) {
                    draft.graph.nodes.append(
                        WorkflowNode(
                            moduleID: descriptor.id,
                            title: descriptor.name,
                            position: CGPoint(x: 180 + Double(draft.graph.nodes.count * 40), y: 180)
                        )
                    )
                    if draft.entryModuleID == nil {
                        draft.entryModuleID = descriptor.id
                    }
                }
            }
            Spacer()
        }
    }

    private var currentWorkflow: WorkflowRecord {
        draft
    }

    private var bindingWorkflow: Binding<WorkflowRecord> {
        Binding(get: { draft }, set: { draft = $0 })
    }
}
```

Update `Flexora/App/MainWindowView.swift`:

```swift
import SwiftUI

struct MainWindowView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationSplitView {
            AppSidebarView(model: model)
        } detail: {
            switch model.route {
            case .home:
                HomeView(model: model)
            case .modules:
                ModuleLibraryView(model: model)
            case .workshop:
                WorkflowWorkshopView(model: model, workflowID: nil)
            case let .workflowEditor(workflowID):
                WorkflowWorkshopView(model: model, workflowID: workflowID)
            case let .task(workflowID):
                WorkflowTaskView(model: model, workflowID: workflowID)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
```

- [ ] **Step 4: Run a build to verify the workshop and task pages compile**

Run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' DEVELOPMENT_TEAM='' build-for-testing
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5: Commit the workflow task and editor shell**

```bash
git add Flexora/App/Task/WorkflowTaskView.swift Flexora/App/Workshop Flexora/App/MainWindowView.swift
git commit -m "feat: add workflow task and workshop views"
```

### Task 5: Fix Video Export Permissions And Rework The Preview Surface

**Files:**
- Create: `FlexoraTests/Video/PreviewControllerTests.swift`
- Modify: `Flexora/Modules/VideoFrameExtraction/PreviewController.swift`
- Modify: `Flexora/Modules/VideoFrameExtraction/ExportController.swift`
- Modify: `Flexora/Modules/VideoFrameExtraction/VideoFrameExtractionWorkspaceView.swift`
- Modify: `FlexoraTests/Video/ExportControllerTests.swift`

- [ ] **Step 1: Write the failing export and preview tests**

Append to `FlexoraTests/Video/ExportControllerTests.swift`:

```swift
    @Test func exportRejectsNonWritableDestinationURL() throws {
        let controller = ExportController()
        let image = NSImage(size: NSSize(width: 8, height: 8))
        image.lockFocus()
        NSColor.systemBlue.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 8, height: 8)).fill()
        image.unlockFocus()

        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("txt")
        try Data().write(to: fileURL)

        #expect(throws: ExportControllerError.destinationNotWritable) {
            try controller.export(
                image: image,
                to: fileURL,
                fileName: "wallpaper-001",
                settings: VideoExportSettings(format: .png, fitMode: .original)
            )
        }
    }
```

Create `FlexoraTests/Video/PreviewControllerTests.swift`:

```swift
import Testing
@testable import Flexora

@MainActor
struct PreviewControllerTests {
    @Test func openAndClosePreviewAreExplicit() {
        let controller = PreviewController()

        controller.openLargePreview()
        #expect(controller.isShowingLargePreview)

        controller.closeLargePreview()
        #expect(!controller.isShowingLargePreview)
    }

    @Test func toggleStillWorksForKeyboardShortcutPath() {
        let controller = PreviewController()

        controller.toggleLargePreview()
        #expect(controller.isShowingLargePreview)

        controller.toggleLargePreview()
        #expect(!controller.isShowingLargePreview)
    }
}
```

- [ ] **Step 2: Run the video tests to verify they fail**

Run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' -only-testing:FlexoraTests/ExportControllerTests -only-testing:FlexoraTests/PreviewControllerTests test
```

Expected: `FAIL` because `ExportController` does not validate the destination directory and `PreviewController` does not yet expose explicit open/close methods.

- [ ] **Step 3: Implement explicit destination validation and immersive preview behavior**

Write `Flexora/Modules/VideoFrameExtraction/PreviewController.swift`:

```swift
import Combine
import Foundation

final class PreviewController: ObservableObject {
    @Published var isShowingLargePreview = false

    func openLargePreview() {
        isShowingLargePreview = true
    }

    func closeLargePreview() {
        isShowingLargePreview = false
    }

    func toggleLargePreview() {
        isShowingLargePreview.toggle()
    }
}
```

Write `Flexora/Modules/VideoFrameExtraction/ExportController.swift`:

```swift
import AppKit
import Foundation

enum ExportControllerError: Error {
    case destinationNotWritable
    case heicEncodingUnavailable
    case missingFrameImage
}

struct ExportController {
    func export(image: NSImage, to url: URL, fileName: String, settings: VideoExportSettings) throws -> URL {
        guard isWritableDirectory(url) else {
            throw ExportControllerError.destinationNotWritable
        }

        let data = try ImageExportEncoding.data(for: image, format: settings.format)
        let outputURL = url
            .appendingPathComponent(fileName)
            .appendingPathExtension(settings.format.rawValue.lowercased())

        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }

        try data.write(to: outputURL, options: .atomic)
        return outputURL
    }

    func userFacingError(for error: ExportControllerError) -> String {
        switch error {
        case .heicEncodingUnavailable:
            return "HEIC export is unavailable for this file. Choose PNG or JPEG instead."
        case .destinationNotWritable:
            return "The selected export location cannot be written to. Choose a different folder and try again."
        case .missingFrameImage:
            return "The selected frame does not have image data available for export."
        }
    }

    private func isWritableDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return false
        }

        return FileManager.default.isWritableFile(atPath: url.path)
    }
}
```

Update the preview and export sections in `Flexora/Modules/VideoFrameExtraction/VideoFrameExtractionWorkspaceView.swift`:

```swift
        .sheet(isPresented: $previewController.isShowingLargePreview) {
            LargePreviewView(candidate: focusedCandidate) {
                previewController.closeLargePreview()
            }
            .frame(minWidth: 900, minHeight: 640)
        }
```

```swift
    private func togglePreviewIfPossible() {
        guard focusedCandidate != nil else {
            return
        }

        if previewController.isShowingLargePreview {
            previewController.closeLargePreview()
        } else {
            previewController.openLargePreview()
        }
    }
```

Replace `LargePreviewView` with:

```swift
private struct LargePreviewView: View {
    let candidate: VideoFrameCandidate?
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.96)
                .ignoresSafeArea()

            if let candidate, let thumbnailImage = candidate.thumbnailImage {
                Image(nsImage: thumbnailImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(20)
            } else {
                ContentUnavailableView("No Frame Focused", systemImage: "photo")
                    .foregroundStyle(.white)
            }
        }
        .background(
            SpaceKeyHandler(onSpace: onClose)
                .frame(width: 0, height: 0)
        )
        .onExitCommand(perform: onClose)
    }
}
```

Keep the horizontal candidate strip and clickable drop zone intact.

- [ ] **Step 4: Run the video tests and a full build**

Run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' -only-testing:FlexoraTests/ExportControllerTests -only-testing:FlexoraTests/PreviewControllerTests test
```

Expected: `PASS` for `ExportControllerTests` and `PreviewControllerTests`.

Then run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' DEVELOPMENT_TEAM='' build-for-testing
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5: Commit the video workflow UX fixes**

```bash
git add Flexora/Modules/VideoFrameExtraction/PreviewController.swift Flexora/Modules/VideoFrameExtraction/ExportController.swift Flexora/Modules/VideoFrameExtraction/VideoFrameExtractionWorkspaceView.swift FlexoraTests/Video/ExportControllerTests.swift FlexoraTests/Video/PreviewControllerTests.swift
git commit -m "fix: improve video export and immersive preview"
```

### Task 6: Final Verification And App-Level Cleanup

**Files:**
- Modify: any newly failing imports or project references introduced by Tasks 1-5

- [ ] **Step 1: Run the targeted test suite for workflow and video coverage**

Run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' \
  -only-testing:FlexoraTests/WorkflowStoreTests \
  -only-testing:FlexoraTests/ToolSessionTests \
  -only-testing:FlexoraTests/ExportControllerTests \
  -only-testing:FlexoraTests/PreviewControllerTests test
```

Expected: all selected tests `PASS`.

- [ ] **Step 2: Run a final build-for-testing pass**

Run:

```bash
xcodebuild -quiet -project Flexora.xcodeproj -scheme Flexora -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' DEVELOPMENT_TEAM='' build-for-testing
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Verify the spec coverage manually against the implemented surfaces**

Use this checklist:

```text
[ ] Sidebar shows Home / Workshop / Modules
[ ] Home shows workflows rather than direct module launch buttons
[ ] Default workflows auto-appear for enabled modules
[ ] Custom workflows can be saved from Workshop
[ ] Disabled modules gray out dependent workflows instead of deleting them
[ ] Modules page uses cards with top-right toggles
[ ] Single-module workflows open the module workspace through Task page
[ ] Multi-module workflows show a graph summary instead of pretending to execute
[ ] Video preview is large, black-backed, button-free, and keyboard-dismissible
[ ] Export failures surface explicit user-facing errors
```

- [ ] **Step 4: Commit the final integrated state**

```bash
git add Flexora FlexoraTests
git commit -m "feat: deliver workflow-centered shell v1"
```

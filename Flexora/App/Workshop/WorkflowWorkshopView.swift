import SwiftUI

struct WorkflowWorkshopView: View {
    @ObservedObject var model: AppModel
    let workflowID: String?

    @State private var draft: WorkflowRecord
    @State private var tagText: String
    @State private var saveStatus: String?

    init(model: AppModel, workflowID: String? = nil) {
        self.model = model
        self.workflowID = workflowID

        let initialDraft = Self.normalized(
            Self.makeInitialDraft(
            workflowID: workflowID,
            workflows: model.workflowStore.workflows
            )
        )
        _draft = State(initialValue: initialDraft)
        _tagText = State(initialValue: initialDraft.tags.map(\.name).joined(separator: ", "))
        _saveStatus = State(initialValue: nil)
    }

    var body: some View {
        HSplitView {
            modulePalette
                .frame(minWidth: 240, idealWidth: 260, maxWidth: 300)

            WorkflowCanvasView(
                workflow: $draft,
                moduleDescriptorsByID: moduleDescriptorsByID,
                onRemoveNode: removeNode
            )

            WorkflowInspectorView(
                workflow: $draft,
                tagText: $tagText,
                saveStatus: saveStatus,
                onSave: saveDraft
            )
        }
        .navigationTitle(workflowID == nil ? "Workshop" : "Workflow Editor")
        .onChange(of: draft) { _, _ in
            saveStatus = nil
        }
        .onChange(of: draft.nodes) { _, _ in
            draft.connections = WorkflowSequentialConnections.sanitized(
                connections: draft.connections,
                nodes: draft.nodes
            )
        }
        .onChange(of: tagText) { _, newValue in
            draft.tags = Self.tags(from: newValue)
        }
    }

    private var moduleDescriptorsByID: [String: ModuleDescriptor] {
        Dictionary(uniqueKeysWithValues: model.runtime.allModules.map { ($0.id, $0) })
    }

    private var modulePalette: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Module Palette")
                    .font(.title3.weight(.semibold))

                Text("Compose and repair workflows by adding modules to the draft graph. V1 stores a simple forward flow in `workflow.connections`.")
                    .foregroundStyle(.secondary)
            }

            if model.runtime.allModules.isEmpty {
                ContentUnavailableView(
                    "No Modules Available",
                    systemImage: "square.stack.3d.up.slash",
                    description: Text("Register modules before building a workflow in the workshop.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(model.runtime.allModules, id: \.id) { module in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(module.name)
                                            .font(.headline)

                                        Text(module.summary.isEmpty ? "No summary provided." : module.summary)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text(model.runtime.isModuleEnabled(module.id) ? "Enabled" : "Disabled")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(
                                            (model.runtime.isModuleEnabled(module.id) ? Color.green : Color.orange)
                                                .opacity(0.14),
                                            in: Capsule()
                                        )
                                        .foregroundStyle(model.runtime.isModuleEnabled(module.id) ? .green : .orange)
                                }

                                Button("Add to Graph") {
                                    addNode(for: module)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(nsColor: .windowBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func addNode(for module: ModuleDescriptor) {
        let node = WorkflowNode(
            id: "\(module.id).\(UUID().uuidString)",
            moduleID: module.id,
            title: module.name
        )
        draft.nodes.append(node)
    }

    private func removeNode(_ node: WorkflowNode) {
        draft.nodes.removeAll { $0.id == node.id }
        draft.connections.removeAll {
            $0.sourceNodeID == node.id || $0.destinationNodeID == node.id
        }
        draft.connections = WorkflowSequentialConnections.sanitized(
            connections: draft.connections,
            nodes: draft.nodes
        )
    }

    private func saveDraft() {
        var normalizedDraft = draft
        normalizedDraft.tags = Self.tags(from: tagText)
        normalizedDraft.connections = WorkflowSequentialConnections.sanitized(
            connections: normalizedDraft.connections,
            nodes: normalizedDraft.nodes
        )
        draft = normalizedDraft
        model.workflowStore.save(normalizedDraft)
        if normalizedDraft.nodes.isEmpty {
            saveStatus = "Saved empty workflow draft as \(normalizedDraft.id). Add at least one module before opening it as a task."
        } else {
            saveStatus = "Saved to WorkflowStore as \(normalizedDraft.id)."
        }
    }

    private static func makeInitialDraft(
        workflowID: String?,
        workflows: [WorkflowRecord]
    ) -> WorkflowRecord {
        if
            let workflowID,
            let workflow = workflows.first(where: { $0.id == workflowID })
        {
            return workflow
        }

        return WorkflowRecord(
            id: "workflow.\(UUID().uuidString.lowercased())",
            title: "Untitled Workflow",
            summary: "",
            source: .userAuthored,
            tags: [],
            nodes: [],
            connections: []
        )
    }

    private static func normalized(_ workflow: WorkflowRecord) -> WorkflowRecord {
        var workflow = workflow
        workflow.connections = WorkflowSequentialConnections.sanitized(
            connections: workflow.connections,
            nodes: workflow.nodes
        )
        return workflow
    }

    private static func tags(from text: String) -> [WorkflowTagRecord] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .reduce(into: [WorkflowTagRecord]()) { tags, name in
                let tagID = slug(for: name)
                guard tags.contains(where: { $0.id == tagID }) == false else {
                    return
                }

                tags.append(WorkflowTagRecord(id: tagID, name: name))
            }
    }

    private static func slug(for value: String) -> String {
        let lowered = value.lowercased()
        let pieces = lowered.split { character in
            character.isLetter == false && character.isNumber == false
        }
        return pieces.joined(separator: "-")
    }
}

import SwiftUI

struct WorkflowInspectorView: View {
    @Binding var workflow: WorkflowRecord
    @Binding var tagText: String
    let saveStatus: String?
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Inspector")
                    .font(.title3.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                    TextField("Workflow title", text: $workflow.title)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.headline)
                    TextEditor(text: $workflow.summary)
                        .frame(minHeight: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    TextField("Comma separated tags", text: $tagText)
                    Text("Tags are stored as simple workflow metadata for filtering and repair context.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Source")
                        .font(.headline)
                    Text(sourceLabel)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Graph Summary")
                        .font(.headline)
                    Text("\(workflow.nodes.count) nodes")
                    Text("\(workflow.connections.count) connections")
                    Text("\(workflow.tags.count) tags")
                }
                .foregroundStyle(.secondary)

                if workflow.nodes.isEmpty {
                    Text("Empty workflows are saved as drafts. Add at least one module before opening the draft as a task.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button(workflow.nodes.isEmpty ? "Save Empty Draft" : "Save Workflow") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)

                if let saveStatus {
                    Text(saveStatus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 360, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var sourceLabel: String {
        switch workflow.source {
        case .moduleDefault(let moduleID):
            return "Module default: \(moduleID)"
        case .userAuthored:
            return "User-authored workflow"
        }
    }
}

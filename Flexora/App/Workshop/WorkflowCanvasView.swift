import SwiftUI

enum WorkflowSequentialConnections {
    static func connectInOrder(nodes: [WorkflowNode]) -> [WorkflowConnection] {
        guard nodes.count > 1 else {
            return []
        }

        return zip(nodes, nodes.dropFirst()).map { source, destination in
            WorkflowConnection(
                id: connectionID(sourceNodeID: source.id, destinationNodeID: destination.id),
                sourceNodeID: source.id,
                destinationNodeID: destination.id
            )
        }
    }

    static func destinationNodeID(
        for sourceNodeID: String,
        nodes: [WorkflowNode],
        existingConnections: [WorkflowConnection]
    ) -> String? {
        sanitized(connections: existingConnections, nodes: nodes)
            .first { $0.sourceNodeID == sourceNodeID }?
            .destinationNodeID
    }

    static func settingDestinationNodeID(
        _ destinationNodeID: String?,
        for sourceNodeID: String,
        nodes: [WorkflowNode],
        existingConnections: [WorkflowConnection]
    ) -> [WorkflowConnection] {
        var destinationsBySource = Dictionary(
            uniqueKeysWithValues: sanitized(connections: existingConnections, nodes: nodes)
                .map { ($0.sourceNodeID, $0.destinationNodeID) }
        )

        if
            let destinationNodeID,
            isValidDestination(destinationNodeID, for: sourceNodeID, nodes: nodes)
        {
            destinationsBySource[sourceNodeID] = destinationNodeID
        } else {
            destinationsBySource.removeValue(forKey: sourceNodeID)
        }

        return orderedConnections(destinationsBySource: destinationsBySource, nodes: nodes)
    }

    static func sanitized(
        connections: [WorkflowConnection],
        nodes: [WorkflowNode]
    ) -> [WorkflowConnection] {
        var destinationsBySource: [String: String] = [:]

        for connection in connections {
            guard destinationsBySource[connection.sourceNodeID] == nil else {
                continue
            }

            guard isValidDestination(connection.destinationNodeID, for: connection.sourceNodeID, nodes: nodes) else {
                continue
            }

            destinationsBySource[connection.sourceNodeID] = connection.destinationNodeID
        }

        return orderedConnections(destinationsBySource: destinationsBySource, nodes: nodes)
    }

    private static func orderedConnections(
        destinationsBySource: [String: String],
        nodes: [WorkflowNode]
    ) -> [WorkflowConnection] {
        nodes.compactMap { node in
            guard
                let destinationNodeID = destinationsBySource[node.id],
                isValidDestination(destinationNodeID, for: node.id, nodes: nodes)
            else {
                return nil
            }

            return WorkflowConnection(
                id: connectionID(sourceNodeID: node.id, destinationNodeID: destinationNodeID),
                sourceNodeID: node.id,
                destinationNodeID: destinationNodeID
            )
        }
    }

    private static func isValidDestination(
        _ destinationNodeID: String,
        for sourceNodeID: String,
        nodes: [WorkflowNode]
    ) -> Bool {
        guard
            let sourceIndex = nodes.firstIndex(where: { $0.id == sourceNodeID }),
            let destinationIndex = nodes.firstIndex(where: { $0.id == destinationNodeID })
        else {
            return false
        }

        return sourceIndex < destinationIndex
    }

    private static func connectionID(sourceNodeID: String, destinationNodeID: String) -> String {
        "\(sourceNodeID)->\(destinationNodeID)"
    }
}

struct WorkflowCanvasView: View {
    @Binding var workflow: WorkflowRecord
    let moduleDescriptorsByID: [String: ModuleDescriptor]
    let onRemoveNode: (WorkflowNode) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Graph Canvas")
                        .font(.title3.weight(.semibold))

                    Text("This V1 canvas records workflow structure and a simple forward flow. It does not execute multi-module graphs.")
                        .foregroundStyle(.secondary)
                }

                if workflow.nodes.isEmpty {
                    ContentUnavailableView(
                        "No Nodes Yet",
                        systemImage: "square.dashed",
                        description: Text("Add modules from the palette to assemble a draft workflow.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 260)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(workflow.nodes) { node in
                            nodeCard(node)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Sequential Flow")
                        .font(.headline)

                    Text("Choose the next step for each node. V1 stores at most one downstream connection per node, following the current node order.")
                        .foregroundStyle(.secondary)

                    if workflow.nodes.count < 2 {
                        Text("Add at least two nodes to record connections.")
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(workflow.nodes.enumerated()), id: \.element.id) { index, node in
                                connectionEditorRow(node: node, index: index)
                            }
                        }

                        HStack(spacing: 12) {
                            Button("Connect in Current Order") {
                                workflow.connections = WorkflowSequentialConnections.connectInOrder(nodes: workflow.nodes)
                            }
                            .buttonStyle(.bordered)

                            Button("Clear Connections") {
                                workflow.connections = []
                            }
                            .buttonStyle(.bordered)
                            .disabled(workflow.connections.isEmpty)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Recorded Connections")
                        .font(.headline)

                    if workflow.connections.isEmpty {
                        Text("No explicit connections recorded.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(workflow.connections) { connection in
                            Text(connectionDescription(for: connection))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private func nodeCard(_ node: WorkflowNode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(node.title)
                        .font(.headline)

                    Text(moduleName(for: node.moduleID))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Remove") {
                    onRemoveNode(node)
                }
                .buttonStyle(.bordered)
            }

            let downstreamNodes = workflow.connections
                .filter { $0.sourceNodeID == node.id }
                .compactMap { connection in
                    workflow.nodes.first(where: { $0.id == connection.destinationNodeID })?.title
                }

            Text(downstreamNodes.isEmpty ? "No downstream connection recorded." : "Feeds: \(downstreamNodes.joined(separator: ", "))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func connectionEditorRow(node: WorkflowNode, index: Int) -> some View {
        let downstreamCandidates = Array(workflow.nodes.dropFirst(index + 1))

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(index + 1). \(node.title)")
                    .font(.headline)

                Spacer()

                Text(moduleName(for: node.moduleID))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if downstreamCandidates.isEmpty {
                Text("End of flow in the current node order.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Picker("Next Step", selection: destinationBinding(for: node.id, nodes: workflow.nodes)) {
                    Text("End of flow")
                        .tag(Optional<String>.none)

                    ForEach(downstreamCandidates) { candidate in
                        Text(candidate.title)
                            .tag(Optional(candidate.id))
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func destinationBinding(for sourceNodeID: String, nodes: [WorkflowNode]) -> Binding<String?> {
        Binding(
            get: {
                WorkflowSequentialConnections.destinationNodeID(
                    for: sourceNodeID,
                    nodes: nodes,
                    existingConnections: workflow.connections
                )
            },
            set: { newDestinationNodeID in
                workflow.connections = WorkflowSequentialConnections.settingDestinationNodeID(
                    newDestinationNodeID,
                    for: sourceNodeID,
                    nodes: nodes,
                    existingConnections: workflow.connections
                )
            }
        )
    }

    private func connectionDescription(for connection: WorkflowConnection) -> String {
        let source = workflow.nodes.first(where: { $0.id == connection.sourceNodeID })?.title ?? connection.sourceNodeID
        let destination = workflow.nodes.first(where: { $0.id == connection.destinationNodeID })?.title ?? connection.destinationNodeID
        return "\(source) -> \(destination)"
    }

    private func moduleName(for moduleID: String) -> String {
        moduleDescriptorsByID[moduleID]?.name ?? moduleID
    }
}

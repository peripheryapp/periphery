import Foundation

/// Workaround for https://github.com/apple/swift/issues/61509.
final class IfLetShorthandPropertyReferenceRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() throws {
        guard SwiftVersion.current.version.isVersion(greaterThanOrEqualTo: "5.7") else { return }

        let unreachableProperties = graph.unreachableDeclarations.filter(\.kind.isVariableKind)
        let properties = graph.assignOnlyProperties.union(unreachableProperties)

        for property in properties {
            guard let propertyName = property.name,
                  let parent = property.parent,
                  parent.declarations.contains(where: { $0.ifLetShorthandIdentifiers.contains(propertyName) })
            else { continue }
            graph.markReachable(property)
        }
    }
}

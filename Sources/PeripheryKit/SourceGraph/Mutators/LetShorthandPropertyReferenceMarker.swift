import Foundation
import Shared

/// Workaround for https://github.com/apple/swift/issues/61509.
final class LetShorthandPropertyReferenceMarker: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() throws {
        guard SwiftVersion.current.version.isVersion(greaterThanOrEqualTo: "5.7") else { return }

        let unusedProperties = graph.unusedDeclarations.filter(\.kind.isVariableKind)
        let properties = graph.assignOnlyProperties.union(unusedProperties)

        for property in properties {
            guard let propertyName = property.name,
                  let parent = property.parent,
                  parent.declarations.contains(where: { $0.letShorthandIdentifiers.contains(propertyName) })
            else { continue }
            graph.markUsed(property)
        }
    }
}

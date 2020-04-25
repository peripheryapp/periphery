import Foundation

/// The following code is perfectly valid:
///
///   class SomeClass: Equatable {}
///
///   func == (lhs: SomeClass, rhs: SomeClass) -> Bool {
///     return true
///   }
///
/// SourceKit provides no information for us to identify that the == func exists in order to conform
/// to Equatable. It appears (I hope!) that this is a quirk of Equatable and possibly just a small
/// number of protocols. It's certainly _not_ valid for a custom protocol to declare a static func
/// and for it to be implemented at static scope like this. for now our only option is to retain
/// specific static infix operators.
final class RootEquatableInfixOperatorRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph, configuration: inject())
    }

    private let graph: SourceGraph
    private let configuration: Configuration
    private let retainedKinds: [(Declaration.Kind, String)] = [
        (.functionOperatorInfix, "==(_:_:)"),
        (.functionOperatorInfix, "!=(_:_:)")
    ]

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func visit() {
        for declaration in graph.rootDeclarations {
            let pair = (declaration.kind, declaration.name ?? "")

            if retainedKinds.contains(where: { $0 == pair }) {
                declaration.markRetained(reason: .rootEquatableInfixOperator)
            }
        }
    }
}

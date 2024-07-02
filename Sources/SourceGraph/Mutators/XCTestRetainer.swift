import Foundation
import Shared

final class XCTestRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let testCaseClassNames: Set<String>

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.testCaseClassNames = Set(configuration.externalTestCaseClasses + ["XCTestCase"])
    }

    func mutate() {
        let immediateTestCaseClasses = graph.declarations(ofKind: .class).filter {
            $0.related.contains {
                guard let name = $0.name else { return false }
                return $0.kind == .class && self.testCaseClassNames.contains(name)
            }
        }

        let subclasses = immediateTestCaseClasses.flatMapSet { graph.subclasses(of: $0) }
        let testCaseClasses = subclasses.union(immediateTestCaseClasses)

        for testCaseClass in testCaseClasses {
            graph.markRetained(testCaseClass)
            let methods = testCaseClass.declarations.filter { $0.kind == .functionMethodInstance }

            for method in methods {
                guard let name = method.name else { continue }
                if name.hasPrefix("test"), name.hasSuffix("()") {
                    graph.markRetained(method)
                }
            }
        }
    }
}

import Foundation
import Shared

final class XCTestRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() {
        let immediateTestCaseClasses = graph.declarations(ofKind: .class).filter {
            $0.related.contains {
                $0.kind == .class && $0.name == "XCTestCase"
            }
        }

        let subclasses = Set(immediateTestCaseClasses.flatMap { graph.subclasses(of: $0) })
        let testCaseClasses = subclasses.union(immediateTestCaseClasses)

        for testCaseClass in testCaseClasses {
            graph.markRetained(testCaseClass)
            let methods = testCaseClass.declarations.filter { $0.kind == .functionMethodInstance }

            for method in methods {
                if method.name?.hasPrefix("test") ?? false {
                    graph.markRetained(method)
                }
            }
        }
    }
}

import Foundation

final class XCTestRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        let immediateTestCaseClasses = graph.declarations(ofKind: .class).filter {
            $0.related.contains {
                $0.kind == .class && $0.name == "XCTestCase"
            }
        }

        let subclasses = Set(immediateTestCaseClasses.flatMap { graph.subclasses(of: $0) })
        let testCaseClasses = subclasses.union(immediateTestCaseClasses)

        for testCaseClass in testCaseClasses {
            testCaseClass.markRetained(reason: .xctest)
            let methods = testCaseClass.declarations.filter { $0.kind == .functionMethodInstance }

            for method in methods {
                if method.name?.hasPrefix("test") ?? false {
                    method.markRetained(reason: .xctest)
                }
            }
        }
    }
}

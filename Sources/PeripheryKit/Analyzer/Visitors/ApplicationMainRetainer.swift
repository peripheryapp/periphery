import Foundation

class ApplicationMainRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        let classes = graph.declarations(ofKind: .class)
        let mainClasses = classes.filter {
            $0.attributes.contains("NSApplicationMain") ||
            $0.attributes.contains("UIApplicationMain")
        }

        mainClasses.forEach {
            $0.markRetained(reason: .applicationMain)

            $0.ancestralDeclarations.forEach {
                $0.markRetained(reason: .applicationMain)
            }
        }
    }
}

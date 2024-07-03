import Foundation
import Shared

final class ObjCAccessibleRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() throws {
        guard configuration.retainObjcAccessible || configuration.retainObjcAnnotated else { return }

        for decl in graph.declarations(ofKinds: Declaration.Kind.accessibleKinds) {
            guard decl.attributes.contains("objc") ||
                    decl.attributes.contains("objc.name") ||
                    decl.attributes.contains("objcMembers") else { continue }

            decl.isObjcAccessible = true
            graph.markRetained(decl)

            if configuration.retainObjcAnnotated {
                if decl.attributes.contains("objcMembers") || decl.kind == .protocol || decl.kind == .extensionClass {
                    decl.declarations.forEach {
                        $0.isObjcAccessible = true
                        graph.markRetained($0)
                    }
                }
            }
        }

        if configuration.retainObjcAnnotated {
            for extDecl in graph.declarations(ofKind: .extensionClass) {
                if let extendedClass = try graph.extendedDeclaration(forExtension: extDecl),
                   extendedClass.attributes.contains("objcMembers") {
                    extDecl.declarations.forEach {
                        $0.isObjcAccessible = true
                        graph.markRetained($0)
                    }
                }
            }
        }
    }
}

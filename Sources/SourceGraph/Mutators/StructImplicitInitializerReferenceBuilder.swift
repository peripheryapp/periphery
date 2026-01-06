import Configuration
import Foundation
import Shared

/// Builds references from struct implicit initializers to the properties it assigns.
final class StructImplicitInitializerReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() throws {
        for structDecl in graph.declarations(ofKind: .struct) {
            let implicitInitDecls = structDecl.declarations.filter { $0.kind == .functionConstructor && $0.isImplicit }

            for implicitInitDecl in implicitInitDecls {
                guard let name = implicitInitDecl.name else { continue }

                let propertyNames = name
                    .dropFirst("init(".count)
                    .dropLast(")".count)
                    .split(separator: ":")
                    .map(String.init)

                let initPropertyDecls = structDecl.declarations.filter {
                    guard $0.kind == .varInstance, let name = $0.name, propertyNames.contains(name)
                    else { return false }

                    return true
                }

                for propertyDecl in initPropertyDecls {
                    guard let setterDecl = propertyDecl.declarations.first(where: { $0.kind == .functionAccessorSetter })
                    else { continue }

                    for decl in [propertyDecl, setterDecl] {
                        for usr in decl.usrs {
                            let ref = Reference(kind: decl.kind, usr: usr, location: implicitInitDecl.location)
                            ref.name = decl.name
                            ref.parent = implicitInitDecl
                            graph.add(ref, from: implicitInitDecl)
                        }
                    }
                }

                // The index contains references to properties at the call site of the implicit
                // initializer. This pattern is contrary to explicit initializers, where only the
                // initializer is referenced. Now that we've built the property references stemming from
                // the implicit initializer, we can remove the additional property references at the
                // call site. This enables assign-only property detection for structs using implicit
                // initializers.
                for initRef in graph.references(to: implicitInitDecl) {
                    guard let caller = initRef.parent, caller != structDecl else { continue }

                    let sortedReferences = caller.references.sorted()

                    for initPropertyDecl in initPropertyDecls {
                        let firstRef = sortedReferences.first { initPropertyDecl.usrs.contains($0.usr) && $0.location > initRef.location }

                        if let firstRef {
                            graph.remove(firstRef)
                        }
                    }
                }
            }
        }
    }
}

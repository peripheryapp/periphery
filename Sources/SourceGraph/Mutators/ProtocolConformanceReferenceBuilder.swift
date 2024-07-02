import Foundation
import Shared

final class ProtocolConformanceReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() {
        let nonInvertibleReferences = referenceConformingDeclarationsImplementedInSuperclass()
        // These nonInvertibleReferences were just created, and are already in their correct place.
        // We're passing them here to the next step so that they're not inverted.
        invertReferencesFromProtocolToDeclaration(nonInvertibleReferences)
    }

    // MARK: - Private

    private func referenceConformingDeclarationsImplementedInSuperclass() -> Set<Reference> {
        var newReferences: Set<Reference> = []
        let protocols = graph.declarations(ofKind: .protocol)

        for proto in protocols {
            // Find all classes that implement this protocol.
            let conformingClasses = graph.references(to: proto)
                .reduce(into: Set<Declaration>()) { result, ref in
                    if ref.isRelated, let parent = ref.parent, parent.kind == .class {
                        result.insert(parent)
                    }
                }

            for conformingClass in conformingClasses {
                // Find declarations defined by the protocol not defined in the class.
                let unimplementedProtoDecls = proto.declarations.filter { protoDeclaration in
                    !conformingClass.declarations.contains { clsDeclaration in
                        protoDeclaration.kind == clsDeclaration.kind &&
                            protoDeclaration.name == clsDeclaration.name
                    }
                }

                if !unimplementedProtoDecls.isEmpty {
                    // Find all superclasses.
                    let superclassDecls = graph.inheritedTypeReferences(of: conformingClass)
                        .filter { $0.kind == .class }
                        .compactMap { graph.explicitDeclaration(withUsr: $0.usr) }
                        .flatMap { $0.declarations }

                    for unimplementedProtoDecl in unimplementedProtoDecls {
                        // Find the implementation declaration in a superclass.
                        let declInSuperclass = superclassDecls.first {
                            $0.kind == unimplementedProtoDecl.kind &&
                            $0.name == unimplementedProtoDecl.name
                        }

                        if let declInSuperclass = declInSuperclass {
                            // Build a reference from the protocol declarations to the
                            // declaration implemented by the superclass.
                            for usr in declInSuperclass.usrs {
                                let reference = Reference(
                                    kind: declInSuperclass.kind,
                                    usr: usr,
                                    location: declInSuperclass.location,
                                    isRelated: true
                                )
                                reference.name = declInSuperclass.name
                                reference.parent = unimplementedProtoDecl
                                graph.add(reference, from: unimplementedProtoDecl)
                                newReferences.insert(reference)
                            }
                        }
                    }
                }
            }
        }

        return newReferences
    }

    private func invertReferencesFromProtocolToDeclaration(_ nonInvertableReferences: Set<Reference>) {
        let relatedReferences = graph.allReferences.filter { $0.isRelated && $0.kind.isProtocolMemberConformingKind }

        for relatedReference in relatedReferences.subtracting(nonInvertableReferences) {
            guard let conformingDeclaration = relatedReference.parent
            else { continue }

            var equivalentDeclarationKinds = [relatedReference.kind]

            // A conforming declaration can be declared either 'class' or 'static', whereas
            // protocol members can only be declared as 'static'.
            if relatedReference.kind == .functionMethodStatic {
                equivalentDeclarationKinds.append(.functionMethodClass)
            } else if relatedReference.kind == .functionMethodClass {
                equivalentDeclarationKinds.append(.functionMethodStatic)
            } else if relatedReference.kind == .varStatic {
                equivalentDeclarationKinds.append(.varClass)
            } else if relatedReference.kind == .varClass {
                equivalentDeclarationKinds.append(.varStatic)
            } else if relatedReference.kind == .associatedtype {
                equivalentDeclarationKinds.append(contentsOf: Declaration.Kind.concreteTypeDeclarableKinds)
            }

            guard equivalentDeclarationKinds.contains(conformingDeclaration.kind),
                conformingDeclaration.name == relatedReference.name else { continue }

            if let protocolDeclaration = graph.explicitDeclaration(withUsr: relatedReference.usr) {
                // Invert the related reference such that instead of the conforming declaration
                // referencing the declaration within the protocol, the protocol declaration
                // now references the conforming declaration.

                // Note: we don't remove this reference if the conforming declaration is a default
                // implementation declared within an extension.
                if !conformingDeclaration.isDeclaredInExtension(kind: .extensionProtocol) {
                    graph.remove(relatedReference)
                }

                for usr in conformingDeclaration.usrs {
                    let newReference = Reference(
                        kind: relatedReference.kind,
                        usr: usr,
                        location: relatedReference.location,
                        isRelated: true
                    )
                    newReference.name = relatedReference.name
                    newReference.parent = protocolDeclaration
                    graph.add(newReference, from: protocolDeclaration)
                }
            } else {
                // The referenced declaration is external, e.g from stdlib/Foundation.
                graph.markRetained(conformingDeclaration)
            }
        }
    }
}

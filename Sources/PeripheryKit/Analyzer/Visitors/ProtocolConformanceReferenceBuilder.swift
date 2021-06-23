import Foundation

final class ProtocolConformanceReferenceBuilder: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        let nonInvertableReferences = referenceConformingDeclarationsImplementedInSuperclass()
        // These nonInvertableReferences were just created, and are already in their correct place.
        // We're passing them here to the next step so that they're not inverted.
        invertReferencesFromProtocolToDeclaration(nonInvertableReferences)
    }

    // MARK: - Private

    private func referenceConformingDeclarationsImplementedInSuperclass() -> Set<Reference> {
        var newReferences: Set<Reference> = []
        let protocols = graph.declarations(ofKind: .protocol)

        for proto in protocols {
            // Find all classes that implement this protocol.
            let conformingClasses = graph.declarations(ofKind: .class).filter {
                $0.related.contains { proto.usrs.contains($0.usr) }
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
                            guard let referenceKind = declInSuperclass.kind.referenceEquivalent else { continue }

                            for usr in declInSuperclass.usrs {
                                let reference = Reference(kind: referenceKind,
                                                          usr: usr,
                                                          location: declInSuperclass.location)
                                reference.name = declInSuperclass.name
                                reference.isRelated = true
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
        let relatedReferences = graph.allReferences.filter { $0.isRelated }

        for relatedReference in relatedReferences.subtracting(nonInvertableReferences) {
            guard let conformingDeclaration = relatedReference.parent,
                  let equivalentDeclarationKind = relatedReference.kind.declarationEquivalent
            else { continue }

            var equivalentDeclarationKinds = [equivalentDeclarationKind]

            // A comforming declaration can be declared either 'class' or 'static', whereas
            // protocol members can only be declared as 'static'.
            if equivalentDeclarationKind == .functionMethodStatic {
                equivalentDeclarationKinds.append(.functionMethodClass)
            } else if equivalentDeclarationKind == .functionMethodClass {
                equivalentDeclarationKinds.append(.functionMethodStatic)
            } else if equivalentDeclarationKind == .varStatic {
                equivalentDeclarationKinds.append(.varClass)
            } else if equivalentDeclarationKind == .varClass {
                equivalentDeclarationKinds.append(.varStatic)
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
                    let newReference = Reference(kind: relatedReference.kind,
                                                 usr: usr,
                                                 location: relatedReference.location)
                    newReference.name = relatedReference.name
                    newReference.parent = protocolDeclaration
                    newReference.isRelated = true
                    graph.add(newReference, from: protocolDeclaration)
                }
            } else {
                // The referenced declaration is external, e.g from stdlib/Foundation.
                graph.markRetained(conformingDeclaration)
            }
        }
    }
}

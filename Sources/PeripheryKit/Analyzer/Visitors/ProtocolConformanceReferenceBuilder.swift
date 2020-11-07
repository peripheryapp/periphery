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
                $0.related.contains { $0.usr == proto.usr }
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
                    let superclassDecls = graph.superclassReferences(of: conformingClass)
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

                            let reference = Reference(kind: referenceKind,
                                                      usr: declInSuperclass.usr,
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

        return newReferences
    }

    private func invertReferencesFromProtocolToDeclaration(_ nonInvertableReferences: Set<Reference>) {
        let relatedReferences = graph.allReferences.filter { $0.isRelated }

        for relatedReference in relatedReferences.subtracting(nonInvertableReferences) {
            guard let conformingDeclaration = relatedReference.parent as? Declaration else { continue }

            if relatedReference.kind == .protocol,
                [.class, .struct].contains(conformingDeclaration.kind) {
                // Remove any references from a class/struct to the protocol it conforms to.
                // A protocol should only be retained if it's used directly, and not simply because
                // a class/struct (which may itself be unsued) conforms to it.

                // However, we can only remove the reference if the protocol does not inherit a foreign protocol,
                // as the foreign protool may be used only by foreign code which is not visibile to us.
                // E.g a protocol may inherit Comparable and implement the operator '<', however we have no way to see
                // that '<' is used when calling sort().

                let inheritsForeignProtocol = graph.superclassReferences(of: conformingDeclaration).contains {
                    graph.explicitDeclaration(withUsr: $0.usr) == nil
                }

                if !inheritsForeignProtocol {
                    graph.remove(relatedReference)

                    // For some reason, a class/struct that conforms to a protocol will have both a
                    // normal reference and a related reference to the protocol from the same
                    // location. We just removed the related reference, so we now need to remove the
                    // normal reference.
                    let redundantReference = conformingDeclaration.references.first {
                        // We're not using Equatable to compare these references sine that will
                        // also take into account 'isRelated'. We're ignoring 'isRelated' because
                        // they will always be different.
                        $0.kind == relatedReference.kind &&
                            $0.usr == relatedReference.usr &&
                            $0.location == relatedReference.location
                    }

                    if let redundantReference = redundantReference {
                        graph.remove(redundantReference)
                    }
                }
            }

            // From this point onward we are only considering absolutely equivalent declarations,
            // typically methods and vars.
            guard let equivalentDeclarationKind = relatedReference.kind.declarationEquivalent else { continue }
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

                let newReference = Reference(kind: relatedReference.kind,
                                             usr: conformingDeclaration.usr,
                                             location: relatedReference.location)
                newReference.name = relatedReference.name
                newReference.parent = protocolDeclaration
                newReference.isRelated = true
                graph.add(newReference, from: protocolDeclaration)
            } else {
                // The referenced declaration is external, e.g from stdlib/Foundation.
                conformingDeclaration.markRetained()
            }
        }
    }
}

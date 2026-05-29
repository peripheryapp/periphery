import Configuration
import Foundation
import Shared

final class SwiftUIRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration
    private static let specialProtocolNames = ["App", "Commands", "LibraryContentProvider", "Scene"]
    private static let applicationDelegateAdaptorStructNames = ["UIApplicationDelegateAdaptor", "NSApplicationDelegateAdaptor"]

    required init(graph: SourceGraph, configuration: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() {
        retainSpecialProtocolConformances()
        retainApplicationDelegateAdaptors()
        unretainPreviewMacroExpansions()
    }

    // MARK: - Private

    private func retainSpecialProtocolConformances() {
        var names = Self.specialProtocolNames

        if configuration.retainSwiftUIPreviews {
            names.append("PreviewProvider")
        }

        graph
            .declarations(ofKinds: [.class, .struct, .enum])
            .lazy
            .filter {
                $0.related.contains {
                    self.graph.isExternal($0) && $0.declarationKind == .protocol && names.contains($0.name)
                }
            }
            .forEach { graph.markRetained($0) }
    }

    private func retainApplicationDelegateAdaptors() {
        // SwiftUI App conformances don't carry a @main attribute in source (the compiler synthesizes
        // the entry point), so mainAttributedDeclarations is empty for SwiftUI apps. Fall back to
        // searching all class/struct declarations when no @main-attributed type is found.
        let candidateParents: Set<Declaration> = graph.mainAttributedDeclarations.isEmpty
            ? graph.declarations(ofKinds: [.class, .struct])
            : graph.mainAttributedDeclarations
        candidateParents
            .forEach { parent in
                let adaptorProperties = parent.declarations
                    .filter { $0.kind == .varInstance }
                    .filter {
                        $0.references.contains {
                            ($0.declarationKind == .struct || $0.declarationKind == .enum) && Self.applicationDelegateAdaptorStructNames.contains($0.name)
                        }
                    }
                guard !adaptorProperties.isEmpty else { return }
                graph.markRetained(parent)
                adaptorProperties.forEach { property in
                    graph.markRetained(property)
                    // The delegate class (e.g. AppDelegate) is passed as a metatype argument
                    // to the adaptor. It exists only within the same file, so Periphery may
                    // suggest downgrading it to fileprivate — but doing so causes a compiler
                    // error because the property referencing it must match its access level.
                    // Unmark it from redundant-internal analysis so no suggestion is emitted.
                    for ref in property.references where ref.declarationKind == .class {
                        if let delegateDecl = graph.declaration(withUsr: ref.usr) {
                            graph.unmarkRedundantInternalAccessibility(delegateDecl)
                        }
                    }
                }
            }
    }

    private func unretainPreviewMacroExpansions() {
        guard !configuration.retainSwiftUIPreviews else { return }

        let previewRegistryUsr = "s:21DeveloperToolsSupport15PreviewRegistryP"
        let macroReferences = graph.references(to: previewRegistryUsr)
        guard !macroReferences.isEmpty else { return }

        for reference in macroReferences {
            if let parent = reference.parent, parent.isImplicit {
                graph.unmarkRetained(parent)

                for decl in parent.declarations {
                    graph.unmarkRetained(decl)
                }
            }
        }
    }
}

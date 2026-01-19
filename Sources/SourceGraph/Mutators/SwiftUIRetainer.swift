import Configuration
import Foundation
import Shared

final class SwiftUIRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration
    private static let specialProtocolNames = ["LibraryContentProvider"]
    private static let applicationDelegateAdaptorStructNames = ["UIApplicationDelegateAdaptor", "NSApplicationDelegateAdaptor"]

    required init(graph: SourceGraph, configuration: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() {
        retainSpecialProtocolConformances()
        retainPreviewMacros()
        retainApplicationDelegateAdaptors()
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
                    self.graph.isExternal($0) && $0.declarationKind == .protocol && names.contains($0.name ?? "")
                }
            }
            .forEach { graph.markRetained($0) }
    }

    private func retainPreviewMacros() {
        // #Preview macros are expanded by the compiler before indexing, creating
        // wrapper structs we detect by their mangled names and characteristic patterns
        let previewDecls = graph.allDeclarations.filter { self.isPreviewMacro($0) }

        if configuration.retainSwiftUIPreviews {
            // With flag: retain preview macros
            // Their references will be processed normally by UsedDeclarationMarker
            previewDecls.forEach { graph.markRetained($0) }
        } else {
            // Without flag: mark preview machinery AND child declarations as ignored
            // This includes the makePreview() function and any other generated code
            // UsedDeclarationMarker will skip processing their references
            for preview in previewDecls {
                graph.markIgnored(preview)
                preview.descendentDeclarations.forEach { graph.markIgnored($0) }
            }
        }
    }

    private func isPreviewMacro(_ decl: Declaration) -> Bool {
        // Match compiler-generated preview wrapper structs with mangled names
        // starting with "$s" and containing "PreviewRegistry". We only detect the parent
        // struct - children (like makePreview()) are handled via descendentDeclarations.
        guard let name = decl.name else { return false }

        return name.hasPrefix("$s") && name.contains("PreviewRegistry")
    }

    private func retainApplicationDelegateAdaptors() {
        graph
            .mainAttributedDeclarations
            .lazy
            .flatMap(\.declarations)
            .filter { $0.kind == .varInstance }
            .filter {
                $0.references.contains {
                    ($0.declarationKind == .struct || $0.declarationKind == .enum) && Self.applicationDelegateAdaptorStructNames.contains($0.name ?? "")
                }
            }
            .forEach { graph.markRetained($0) }
    }
}

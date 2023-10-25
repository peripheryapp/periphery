import Shared

final class RedundantInternalAccessibilityMarker: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() throws {
        guard !configuration.disableRedundantInternalAnalysis else { return }

		let nonExtensionKinds = graph.rootDeclarations.filter { !$0.kind.isExtensionKind }
		let extensionKinds = graph.rootDeclarations.filter { $0.kind.isExtensionKind }

		for decl in nonExtensionKinds {
			try validate(decl)
		}

		for decl in extensionKinds {
			try validateExtension(decl)
		}
    }

    // MARK: - Private

	private func validate(_ decl: Declaration) throws {
        // Check if the declaration is [explicitly/implicitly] internal, and is referenced in multiple files.
        if decl.accessibility.value == .internal {
            if try !isReferencedCrossFile(decl) {
                mark(decl)
            }

        } else {
            try markInternalDescendentDeclarations(from: decl)
        }
    }

	private func validateExtension(_ decl: Declaration) throws {
		// Don't validate accessibility of extension, but validate the descendents.
		try markInternalDescendentDeclarations(from: decl)
	}

    private func mark(_ decl: Declaration) {
        // This declaration may already be retained by a comment command.
        guard !graph.isRetained(decl) else { return }
        graph.markRedundantInternalAccessibility(decl, file: decl.location.file)
    }

    private func markInternalDescendentDeclarations(from decl: Declaration) throws {
        for descDecl in descendentInternalDeclarations(from: decl) {
			if try !isReferencedCrossFile(descDecl) && !isImplementingProtocol(descDecl) && !descDecl.isOverride {
				mark(descDecl)
			}
        }
    }

	private func isImplementingProtocol(_ decl: Declaration) throws -> Bool {
		guard let parent: Declaration = decl.parent else { return false }
		let protocols: [Reference] = parent.related.filter { $0.kind == .protocol }
		guard !protocols.isEmpty else { return false }		// no protocol at all
		let declarations: [Declaration] = protocols.compactMap { graph.explicitDeclaration(withUsr: $0.usr) }
		guard !declarations.isEmpty else { return true }	// If protocol isn't actually defined here, we don't have a way to match, so assume it's OK

		let protocolMethods: [Declaration] = declarations.map { $0.declarations }.flatMap { $0 }
		let matchingProtocol: Declaration? = protocolMethods.first { $0.kind == decl.kind && $0.name == decl.name }
		return matchingProtocol != nil
	}

    private func isReferencedCrossFile(_ decl: Declaration) throws -> Bool {
        let referenceFiles = try nonTestableFilesReferencing(decl)
        return !referenceFiles.subtracting([decl.location.file]).isEmpty
    }

    private func nonTestableFilesReferencing(_ decl: Declaration) throws -> Set<SourceFile> {
        let referenceFiles = Set(graph.references(to: decl).map { $0.location.file })
        return referenceFiles
    }

    private func descendentInternalDeclarations(from decl: Declaration) -> Set<Declaration> {
        let internalDeclarations = decl.declarations.filter { $0.accessibility.value == .internal }
        return Set(internalDeclarations.flatMap { descendentInternalDeclarations(from: $0) }).union(internalDeclarations)
    }
}

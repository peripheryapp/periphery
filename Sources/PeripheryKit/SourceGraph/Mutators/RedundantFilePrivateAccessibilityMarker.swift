import Shared

final class RedundantFilePrivateAccessibilityMarker: SourceGraphMutator {
	private let graph: SourceGraph
	private let configuration: Configuration

	required init(graph: SourceGraph, configuration: Configuration) {
		self.graph = graph
		self.configuration = configuration
	}

	func mutate() throws {
		guard !configuration.disableRedundantFilePrivateAnalysis else { return }

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
		// Check if the declaration is explicitly fileprivate, and is referenced in multiple files.
		if decl.accessibility.isExplicitly(.fileprivate) {
			if try !isReferencedCrossScope(decl) {
				// fileprivate accessibility is too exposed.
				mark(decl)
			}
		} else {
			// Look for descendent declarations that are not referenced outside of their scope that can be private
			try markFilePrivateDescendentDeclarations(from: decl)
		}
	}

	private func validateExtension(_ decl: Declaration) throws {
		// Don't validate accessibility of extension, but validate the descendents.
		try markFilePrivateDescendentDeclarations(from: decl)
	}

	private func mark(_ decl: Declaration) {
		// This declaration may already be retained by a comment command.
		guard !graph.isRetained(decl) else { return }
		graph.markRedundantFilePrivateAccessibility(decl, file: decl.location.file)
	}

	private func markFilePrivateDescendentDeclarations(from decl: Declaration) throws {
		for descDecl in descendentFilePrivateDeclarations(from: decl) {
			if try !isReferencedCrossScope(descDecl) {
				mark(descDecl)
			}
		}
	}

	private func isReferencedCrossScope(_ decl: Declaration) throws -> Bool {
		let referenceDeclarations: Set<Declaration> = try nonTestableDeclarationsReferencing(decl)
		let ancestralDeclarations: Set<Declaration> = decl.ancestralDeclarations
		let otherDeclarations: Set<Declaration> = referenceDeclarations.subtracting(ancestralDeclarations)
		// other declarations using this, but also this has SOME ancestral declaration to be considered referenced
		// in a way that would require fileprivate not private
		return !otherDeclarations.isEmpty && !ancestralDeclarations.isEmpty
	}

	/*
	 (lldb) po graph.references(to: decl).map { $0.parent?.ancestralDeclarations }


	 (lldb) po graph.references(to: decl).map { Array($0.parent?.ancestralDeclarations ?? []) }.flatMap { $0 }



	 */

	private func nonTestableDeclarationsReferencing(_ decl: Declaration) throws -> Set<Declaration> {
		let result = Set(graph.references(to: decl).map { Array($0.parent?.ancestralDeclarations ?? []) }.flatMap { $0 })
		return result
	}

	private func descendentFilePrivateDeclarations(from decl: Declaration) -> Set<Declaration> {
		let fileprivateDeclarations = decl.declarations.filter { !$0.isImplicit && $0.accessibility.isExplicitly(.fileprivate) }
		return Set(fileprivateDeclarations.flatMap { descendentFilePrivateDeclarations(from: $0) }).union(fileprivateDeclarations)
	}
}

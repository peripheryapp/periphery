import XCTest
import PeripheryKit
import Shared

open class SourceGraphTestCase: XCTestCase {
    static var graph = SourceGraph()
    static var configuration: Configuration!

    var graph: SourceGraph! {
        get {
            Self.graph
        }
        set {
            Self.graph = newValue
        }
    }

    var configuration: Configuration { Self.configuration }

    private var scopedDeclarationStack: [Declaration] = []

    class open override func setUp() {
        super.setUp()
        configuration = inject()
        configuration.quiet = true
    }

    open override func setUp() {
        super.setUp()
        configuration.reset()
    }

    func assertReferenced(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, file: file, line: line) else { return }

        if !graph.reachableDeclarations.contains(declaration) {
            XCTFail("Expected declaration to be referenced: \(declaration)", file: file, line: line)
        }

        scopedDeclarationStack.append(declaration)
        scopedAssertions?()
        scopedDeclarationStack.removeLast()
    }

    func assertNotReferenced(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, file: file, line: line) else { return }

        if !graph.unreachableDeclarations.contains(declaration) {
            XCTFail("Expected declaration to not be referenced: \(declaration)", file: file, line: line)
        }

        scopedDeclarationStack.append(declaration)
        scopedAssertions?()
        scopedDeclarationStack.removeLast()
    }

    func assertRedundantProtocol(_ name: String, implementedBy conformances: DeclarationDescription..., file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(.protocol(name), file: file, line: line) else { return }

        if let references = graph.redundantProtocols[declaration] {
            let decls = references.compactMap { $0.parent }

            for conformance in conformances {
                if !decls.contains(where: { $0.kind == conformance.kind && $0.name == conformance.name }) {
                    XCTFail("Expected \(conformance) to implement protocol '\(name)'.", file: file, line: line)
                }
            }
        } else {
            XCTFail("Expected '\(name)' to be redundant.", file: file, line: line)
        }
    }

    func assertNotRedundantProtocol(_ name: String, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(.protocol(name), file: file, line: line) else { return }

        if graph.redundantProtocols.keys.contains(declaration) {
            XCTFail("Expected '\(name)' to not be redundant.", file: file, line: line)
        }
    }

    func assertAccessibility(_ description: DeclarationDescription, _ accessibility: Accessibility, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, file: file, line: line) else { return }

        if declaration.accessibility.value != accessibility {
            XCTFail("Expected \(description) to have \(accessibility) accessibility, but found \(declaration.accessibility.value).", file: file, line: line)
        }

        scopedDeclarationStack.append(declaration)
        scopedAssertions?()
        scopedDeclarationStack.removeLast()
    }

    func assertRedundantPublicAccessibility(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, in: graph.allDeclarationsUnmodified, file: file, line: line) else { return }

        if !graph.redundantPublicAccessibility.keys.contains(declaration) {
            XCTFail("Expected declaration to have redundant public accessibility: \(declaration)", file: file, line: line)
        }

        scopedDeclarationStack.append(declaration)
        scopedAssertions?()
        scopedDeclarationStack.removeLast()
    }

    func assertNotRedundantPublicAccessibility(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, in: graph.allDeclarationsUnmodified, file: file, line: line) else { return }

        if graph.redundantPublicAccessibility.keys.contains(declaration) {
            XCTFail("Expected declaration to not have redundant public accessibility: \(declaration)", file: file, line: line)
        }

        scopedDeclarationStack.append(declaration)
        scopedAssertions?()
        scopedDeclarationStack.removeLast()
    }

    func assertUsedParameter(_ name: String, file: StaticString = #file, line: UInt = #line) {
        let declaration = materialize(.varParameter(name), fail: false, file: file, line: line)

        if declaration != nil {
            XCTFail("Expected parameter '\(name)' to be used.", file: file, line: line)
        }
    }

    // MARK: - Private

    private func materialize(_ description: DeclarationDescription, in defaultDeclarationSet: Set<Declaration>? = nil, fail: Bool = true, file: StaticString, line: UInt) -> Declaration? {
        let scopedDeclarations: Set<Declaration>

        if let scopedDeclaration = scopedDeclarationStack.last {
            scopedDeclarations = scopedDeclaration.declarations.union(scopedDeclaration.unusedParameters)
        } else {
            scopedDeclarations = defaultDeclarationSet ?? graph.rootDeclarations
        }

        if let declaration = scopedDeclarations.first(where: { $0.kind == description.kind && $0.name == description.name }) {
            return declaration
        }

        if fail {
            XCTFail("Declaration not found: \(description).", file: file, line: line)
        }

        return nil
    }
}

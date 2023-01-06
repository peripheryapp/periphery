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

    private var scopeStack: [DeclarationScope] = []

    class open override func setUp() {
        super.setUp()
        configuration = Configuration.shared
        configuration.quiet = true
    }

    open override func setUp() {
        super.setUp()
        configuration.reset()
    }

    func assertReferenced(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, file: file, line: line) else { return }

        if !graph.usedDeclarations.contains(declaration) {
            XCTFail("Expected declaration to be referenced: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertNotReferenced(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, file: file, line: line) else { return }

        if !graph.unusedDeclarations.contains(declaration) {
            XCTFail("Expected declaration to not be referenced: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
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

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertRedundantPublicAccessibility(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, in: graph.allDeclarationsUnmodified, file: file, line: line) else { return }

        if !graph.redundantPublicAccessibility.keys.contains(declaration) {
            XCTFail("Expected declaration to have redundant public accessibility: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertNotRedundantPublicAccessibility(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, in: graph.allDeclarationsUnmodified, file: file, line: line) else { return }

        if graph.redundantPublicAccessibility.keys.contains(declaration) {
            XCTFail("Expected declaration to not have redundant public accessibility: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertUsedParameter(_ name: String, file: StaticString = #file, line: UInt = #line) {
        let declaration = materialize(.varParameter(name), fail: false, file: file, line: line)

        if declaration != nil {
            XCTFail("Expected parameter '\(name)' to be used.", file: file, line: line)
        }
    }

    func assertAssignOnlyProperty(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, file: file, line: line) else { return }

        if !graph.assignOnlyProperties.contains(declaration) {
            XCTFail("Expected property to be assign-only: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertNotAssignOnlyProperty(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, file: file, line: line) else { return }

        if graph.assignOnlyProperties.contains(declaration) {
            XCTFail("Expected property to not be assign-only: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func module(_ name: String, scopedAssertions: (() -> Void)? = nil) {
        scopeStack.append(.module(name))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func materialize(_ descriptions: [DeclarationDescription], in defaultDeclarations: Set<Declaration>? = nil, fail: Bool = true, file: StaticString = #file, line: UInt = #line) throws -> Declaration? {
        let allDeclarations = defaultDeclarations ?? graph.rootDeclarations
        let scopeDescriptions = descriptions.dropLast()
        let scopedDeclarations = scopeDescriptions.reduce(into: allDeclarations) { result, description in
            if description.kind == .module {
                result = result.filter { $0.location.file.modules.contains(description.name) }
            } else {
                if let declaration = materialize(description, in: result, file: file, line: line) {
                    result = [declaration]
                }
            }
        }

        return materialize(try XCTUnwrap(descriptions.last), in: scopedDeclarations, fail: fail, file: file, line: line)
    }

    // MARK: - Private

    private func materialize(_ description: DeclarationDescription, in defaultDeclarations: Set<Declaration>? = nil, fail: Bool = true, file: StaticString, line: UInt) -> Declaration? {
        let declarations = scopedDeclarations(from: defaultDeclarations)

        let matchingDeclarations = declarations.filter { $0.kind == description.kind && $0.name == description.name }
        var matchedDeclaration: Declaration?

        if let line = description.line {
            matchedDeclaration = matchingDeclarations.first(where: { $0.location.line == line })
        } else {
            matchedDeclaration = matchingDeclarations.first
        }

        if matchedDeclaration == nil, fail {
            XCTFail("Declaration not found: \(description).", file: file, line: line)
        }

        return matchedDeclaration
    }

    private func scopedDeclarations(from defaultDeclarations: Set<Declaration>? = nil) -> Set<Declaration> {
        let allDeclarations = defaultDeclarations ?? graph.rootDeclarations

        guard !scopeStack.isEmpty else {
            return allDeclarations
        }

        return scopeStack.reduce(into: allDeclarations) { result, scope in
            switch scope {
            case let .declaration(declaration):
                if result.contains(declaration) {
                    result = declaration.declarations.union(declaration.unusedParameters)
                }
            case let .module(module):
                result = result.filter { $0.location.file.modules.contains(module) }
            }
        }
    }
}

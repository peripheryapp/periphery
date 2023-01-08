import XCTest
import SystemPackage
@testable import PeripheryKit
import Shared

open class SourceGraphTestCase: XCTestCase {
    static var driver: ProjectDriver!
    static var configuration: Configuration!
    static var graph = SourceGraph()

    private static var allIndexedDeclarations: Set<Declaration> = []

    let performKnownFailures = false
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

    override open func tearDown() {
        super.tearDown()

        if (testRun?.failureCount ?? 0) > 0 {
            print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
            SourceGraphDebugger(graph: Self.graph).describeGraph()
            print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
        }
    }

    static func build(driver driverType: ProjectDriver.Type, projectPath: FilePath = ProjectRootPath) {
        projectPath.chdir {
            driver = try! driverType.build()
            try! driver.build()
        }
    }

    static func index() {
        graph = SourceGraph()
        try! Self.driver.index(graph: graph)
        allIndexedDeclarations = graph.allDeclarations
        try! SourceGraphMutatorRunner.perform(graph: graph)
    }

    func assertReferenced(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, file: file, line: line) else { return }

        if !Self.graph.usedDeclarations.contains(declaration) {
            XCTFail("Expected declaration to be referenced: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertNotReferenced(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, file: file, line: line) else { return }

        if !Self.graph.unusedDeclarations.contains(declaration) {
            XCTFail("Expected declaration to not be referenced: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertRedundantProtocol(_ name: String, implementedBy conformances: DeclarationDescription..., file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(.protocol(name), file: file, line: line) else { return }

        if let references = Self.graph.redundantProtocols[declaration] {
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

        if Self.graph.redundantProtocols.keys.contains(declaration) {
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
        guard let declaration = materialize(description, in: Self.allIndexedDeclarations, file: file, line: line) else { return }

        if !Self.graph.redundantPublicAccessibility.keys.contains(declaration) {
            XCTFail("Expected declaration to have redundant public accessibility: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertNotRedundantPublicAccessibility(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, in: Self.allIndexedDeclarations, file: file, line: line) else { return }

        if Self.graph.redundantPublicAccessibility.keys.contains(declaration) {
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

        if !Self.graph.assignOnlyProperties.contains(declaration) {
            XCTFail("Expected property to be assign-only: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertNotAssignOnlyProperty(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, file: file, line: line) else { return }

        if Self.graph.assignOnlyProperties.contains(declaration) {
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
        let allDeclarations = defaultDeclarations ?? Self.graph.rootDeclarations

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

import Configuration
@testable import Indexer
import Logger
@testable import PeripheryKit
import Shared
@testable import SourceGraph
import SystemPackage
import XCTest

open class SourceGraphTestCase: XCTestCase {
    static var plan: IndexPlan!
    static var shell: Shell!
    static var logger: Logger!
    static var results: [ScanResult] = []

    private static var graph: SourceGraph!
    private static var allIndexedDeclarations: Set<Declaration> = []

    private var scopeStack: [DeclarationScope] = []

    override open class func setUp() {
        super.setUp()
        logger = Logger(quiet: true)
        shell = Shell(logger: logger)
        let configuration = Configuration()
        configuration.quiet = true
        graph = SourceGraph(configuration: configuration, logger: logger)
    }

    override open func tearDown() {
        super.tearDown()

        if (testRun?.failureCount ?? 0) > 0 {
            print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
            SourceGraphDebugger(graph: Self.graph).describeGraph()
            print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
        }
    }

    func index(sourceFiles: [FilePath]? = nil, configuration: Configuration = .init()) {
        Self.index(sourceFiles: sourceFiles, configuration: configuration)
    }

    static func index(sourceFiles: [FilePath]? = nil, configuration: Configuration) {
        var newPlan = plan!

        if let sourceFiles {
            newPlan = IndexPlan(
                sourceFiles: plan.sourceFiles.filter { sourceFiles.contains($0.key.path) },
                plistPaths: plan.plistPaths,
                xibPaths: plan.xibPaths,
                xcDataModelPaths: plan.xcDataModelPaths,
                xcMappingModelPaths: plan.xcMappingModelPaths
            )
        }

        graph = SourceGraph(configuration: configuration, logger: logger)
        let swiftVersion = SwiftVersion(shell: shell)
        let pipeline = IndexPipeline(
            plan: newPlan,
            graph: SynchronizedSourceGraph(graph: graph),
            logger: logger.contextualized(with: "index"),
            configuration: configuration,
            swiftVersion: swiftVersion
        )
        try! pipeline.perform()

        allIndexedDeclarations = graph.allDeclarations
        try! SourceGraphMutatorRunner(
            graph: graph,
            logger: logger,
            configuration: configuration,
            swiftVersion: swiftVersion
        ).perform()
        results = ScanResultBuilder.build(for: graph)
    }

    func assertReferenced(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        if case .module = description.kind {
            if let declaration = Self.graph.unusedModuleImports.first(where: { $0.name == description.name }) {
                XCTFail("Expected declaration to be referenced: \(declaration)", file: file, line: line)
            }
        } else {
            guard let declaration = materialize(description, file: file, line: line) else { return }

            if !Self.graph.usedDeclarations.contains(declaration) {
                XCTFail("Expected declaration to be referenced: \(declaration)", file: file, line: line)
            }

            scopeStack.append(.declaration(declaration))
            scopedAssertions?()
            scopeStack.removeLast()
        }
    }

    func assertNotReferenced(_ description: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        if case .module = description.kind {
            if Self.graph.unusedModuleImports.first(where: { $0.name == description.name }) == nil {
                XCTFail("Expected module to not be referenced: \(description.name)", file: file, line: line)
            }

        } else {
            guard let declaration = materialize(description, file: file, line: line) else { return }

            if !Self.results.unusedDeclarations.contains(declaration) {
                XCTFail("Expected declaration to not be referenced: \(declaration)", file: file, line: line)
            }
        }
    }

    func assertRedundantProtocol(
        _ name: String,
        implementedBy conformances: DeclarationDescription...,
        inherits inheritedProtocols: DeclarationDescription...,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let declaration = materialize(.protocol(name), file: file, line: line) else { return }

        if let tuple = Self.results.redundantProtocolDeclarations[declaration] {
            let decls = tuple.references.compactMap(\.parent)

            for conformance in conformances where !decls.contains(where: { $0.kind == conformance.kind && $0.name == conformance.name }) {
                XCTFail("Expected \(conformance) to implement protocol '\(name)'.", file: file, line: line)
            }

            for inherited in inheritedProtocols where !tuple.inherited.contains(inherited.name) {
                XCTFail("Expected \(name) to inherit protocol '\(inherited.name)'.", file: file, line: line)
            }
        } else {
            XCTFail("Expected '\(name)' to be redundant.", file: file, line: line)
        }
    }

    func assertNotRedundantProtocol(_ name: String, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(.protocol(name), file: file, line: line) else { return }

        if Self.results.redundantProtocolDeclarations.keys.contains(declaration) {
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

        if !Self.results.redundantPublicAccessibilityDeclarations.contains(declaration) {
            XCTFail("Expected declaration to have redundant public accessibility: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertNotRedundantPublicAccessibility(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, in: Self.allIndexedDeclarations, file: file, line: line) else { return }

        if Self.results.redundantPublicAccessibilityDeclarations.contains(declaration) {
            XCTFail("Expected declaration to not have redundant public accessibility: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertRedundantInternalAccessibility(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, in: Self.allIndexedDeclarations, file: file, line: line) else { return }

        if !Self.results.redundantInternalAccessibilityDeclarations.contains(declaration) {
            XCTFail("Expected declaration to have redundant internal accessibility: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertNotRedundantInternalAccessibility(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, in: Self.allIndexedDeclarations, file: file, line: line) else { return }

        if Self.results.redundantInternalAccessibilityDeclarations.contains(declaration) {
            XCTFail("Expected declaration to not have redundant internal accessibility: \(declaration)", file: file, line: line)
        }

        scopeStack.append(.declaration(declaration))
        scopedAssertions?()
        scopeStack.removeLast()
    }

    func assertNotRedundantFilePrivateAccessibility(_ description: DeclarationDescription, scopedAssertions: (() -> Void)? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, in: Self.allIndexedDeclarations, file: file, line: line) else { return }

        if Self.results.redundantFilePrivateAccessibilityDeclarations.contains(declaration) {
            XCTFail("Expected declaration to not have redundant fileprivate accessibility: \(declaration)", file: file, line: line)
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

        if !Self.results.assignOnlyPropertyDeclarations.contains(declaration) {
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

    func assertOverrides(_ description: DeclarationDescription, _ overrides: [CommentCommand.Override], file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, file: file, line: line) else {
            XCTFail("Failed to materialize \(description)", file: file, line: line)
            return
        }

        let declOverrides = declaration.commentCommands.flatMap {
            if case let .override(overrides) = $0 {
                return overrides
            }

            return []
        }

        for override in overrides {
            if !declOverrides.contains(override) {
                XCTFail("Expected override: \(override)", file: file, line: line)
            }
        }
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
        let matchedDeclaration = if let line = description.line {
            matchingDeclarations.first(where: { $0.location.line == line })
        } else {
            matchingDeclarations.first
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

private extension [ScanResult] {
    var unusedDeclarations: Set<Declaration> {
        compactMapSet {
            if case .unused = $0.annotation {
                return $0.declaration
            }

            return nil
        }
    }

    var assignOnlyPropertyDeclarations: Set<Declaration> {
        compactMapSet {
            if case .assignOnlyProperty = $0.annotation {
                return $0.declaration
            }

            return nil
        }
    }

    var redundantProtocolDeclarations: [Declaration: (references: Set<Reference>, inherited: Set<String>)] {
        reduce(into: .init()) { result, scanResult in
            if case let .redundantProtocol(references, inherited) = scanResult.annotation {
                result[scanResult.declaration] = (references, inherited)
            }
        }
    }

    var redundantPublicAccessibilityDeclarations: Set<Declaration> {
        compactMapSet {
            if case .redundantPublicAccessibility = $0.annotation {
                return $0.declaration
            }

            return nil
        }
    }

    var redundantInternalAccessibilityDeclarations: Set<Declaration> {
        compactMapSet {
            if case .redundantInternalAccessibility = $0.annotation {
                return $0.declaration
            }

            return nil
        }
    }

    var redundantFilePrivateAccessibilityDeclarations: Set<Declaration> {
        compactMapSet {
            if case .redundantFilePrivateAccessibility = $0.annotation {
                return $0.declaration
            }

            return nil
        }
    }
}

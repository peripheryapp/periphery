import XCTest
import PathKit
import Shared
import TestShared
@testable import PeripheryKit

class RedundantPublicAccessabilityTest: SourceGraphTestCase {
    static private var graph: SourceGraph!

    override var graph: SourceGraph! {
        get {
            Self.graph
        }
        set {
            Self.graph = newValue
        }
    }

    override static func setUp() {
        super.setUp()

        let configuration: Configuration = inject()
        configuration.outputFormat = .json

        AccessabilityProjectPath.chdir {
            let package = try! SPM.Package.load()
            let driver = SPMProjectDriver(
                package: package,
                targets: package.targets,
                configuration: configuration,
                logger: inject()
            )

            try! driver.build()
            graph = SourceGraph()
            try! driver.index(graph: graph)
            try! Analyzer.perform(graph: graph)
        }
    }

    func testRedundantPublicType() {
        XCTAssertRedundantPublicAccessibility((.class, "RedundantPublicType"))
        XCTAssertRedundantPublicAccessibility((.functionMethodInstance, "redundantPublicFunction()"), descendentOf: (.class, "RedundantPublicType"))
    }

    func testPublicDeclarationInInternalParent() {
        XCTAssertNotRedundantPublicAccessibility((.class, "PublicDeclarationInInternalParent"))
        XCTAssertRedundantPublicAccessibility((.functionMethodInstance, "somePublicFunc()"), descendentOf: (.class, "PublicDeclarationInInternalParent"))
    }

    func testPublicExtensionOnRedundantPublicKind() {
        XCTAssertRedundantPublicAccessibility((.class, "PublicExtensionOnRedundantPublicKind"))
        XCTAssertRedundantPublicAccessibility((.extensionClass, "PublicExtensionOnRedundantPublicKind"))
    }

    func testPublicTypeUsedAsPublicPropertyType() {
        XCTAssertNotRedundantPublicAccessibility((.class, "PublicTypeUsedAsPublicPropertyType"))
        XCTAssertNotRedundantPublicAccessibility((.struct, "PublicTypeUsedAsPublicPropertyGenericArgumentType"))
        XCTAssertNotRedundantPublicAccessibility((.class, "PublicTypeUsedAsPublicPropertyArrayType"))
    }

    func testPublicTypeUsedAsPublicFunctionParameterType() {
        XCTAssertNotRedundantPublicAccessibility((.class, "PublicTypeUsedAsPublicFunctionParameterType"))
        XCTAssertNotRedundantPublicAccessibility((.class, "PublicTypeUsedAsPublicFunctionParameterTypeClosureArgument"))
        XCTAssertNotRedundantPublicAccessibility((.class, "PublicTypeUsedAsPublicFunctionParameterTypeClosureReturnType"))
    }

    func testPublicTypeUsedAsPublicFunctionReturnType() {
        XCTAssertNotRedundantPublicAccessibility((.class, "PublicTypeUsedAsPublicFunctionReturnType"))
        XCTAssertNotRedundantPublicAccessibility((.class, "PublicTypeUsedAsPublicFunctionReturnTypeClosureArgument"))
        XCTAssertNotRedundantPublicAccessibility((.class, "PublicTypeUsedAsPublicFunctionReturnTypeClosureReturnType"))
    }

    func testPublicTypeUsedInPublicFunctionBody() {
        XCTAssertRedundantPublicAccessibility((.class, "PublicTypeUsedInPublicFunctionBody"))
    }

    func testIgnoreCommentCommands() {
        XCTAssertNotRedundantPublicAccessibility((.class, "IgnoreCommentCommand"))
        XCTAssertNotRedundantPublicAccessibility((.class, "IgnoreAllCommentCommand"))
    }

    func testTestableImport() {
        XCTAssertRedundantPublicAccessibility((.class, "RedundantPublicTestableImportClass"))
        XCTAssertRedundantPublicAccessibility((.varInstance, "testableProperty"), descendentOf: (.class, "RedundantPublicTestableImportClass"))
        XCTAssertNotRedundantPublicAccessibility((.class, "NotRedundantPublicTestableImportClass"))
    }

    func testFunctionGenericParameter() {
        XCTAssertNotRedundantPublicAccessibility((.protocol, "PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolA"))
        XCTAssertNotRedundantPublicAccessibility((.protocol, "PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolB"))
    }

    func testFunctionGenericRequirement() {
        XCTAssertNotRedundantPublicAccessibility((.protocol, "PublicTypeUsedAsPublicFunctionGenericRequirement_Protocol"))
    }

    func testGenericClassParameter() {
        XCTAssertNotRedundantPublicAccessibility((.protocol, "PublicTypeUsedAsPublicClassGenericParameter_ProtocolA"))
        XCTAssertNotRedundantPublicAccessibility((.protocol, "PublicTypeUsedAsPublicClassGenericParameter_ProtocolB"))
    }

    func testClassGenericRequirement() {
        XCTAssertNotRedundantPublicAccessibility((.protocol, "PublicTypeUsedAsPublicClassGenericRequirement_Protocol"))
    }

    // MARK: - Private

    private func XCTAssertRedundantPublicAccessibility(_ description: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, in: graph.allDeclarationsUnmodified) else { return }

        if !graph.redundantPublicAccessibility.keys.contains(declaration) {
            XCTFail("Expected declaration to have redundant public accessibility: \(declaration)", file: file, line: line)
        }
    }

    private func XCTAssertRedundantPublicAccessibility(_ description: DeclarationDescription, descendentOf parentDescriptions: DeclarationDescription..., file: StaticString = #file, line: UInt = #line) {
        guard let parentDeclaration = materialize(parentDescriptions, in: graph.allDeclarationsUnmodified),
              let descendent = materialize(description, in: parentDeclaration.descendentDeclarations)
        else { return }

        if !graph.redundantPublicAccessibility.keys.contains(descendent) {
            XCTFail("Expected declaration to have redundant public accessibility: \(descendent)", file: file, line: line)
        }
    }

    func XCTAssertNotRedundantPublicAccessibility(_ description: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description, in: graph.allDeclarationsUnmodified) else { return }

        if graph.redundantPublicAccessibility.keys.contains(declaration) {
            XCTFail("Expected declaration to not have redundant public accessibility: \(declaration)", file: file, line: line)
        }
    }
}

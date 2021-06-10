import XCTest
import Shared
@testable import TestShared
@testable import PeripheryKit

class RedundantPublicAccessabilityTest: SourceGraphTestCase {
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
            try! driver.index(graph: graph)
            try! Analyzer.perform(graph: graph)
        }
    }

    func testRedundantPublicType() {
        assertRedundantPublicAccessibility(.class("RedundantPublicType")) {
            self.assertRedundantPublicAccessibility(.functionMethodInstance("redundantPublicFunction()"))
        }
    }

    func testPublicDeclarationInInternalParent() {
        assertNotRedundantPublicAccessibility(.class("PublicDeclarationInInternalParent")) {
            self.assertRedundantPublicAccessibility(.functionMethodInstance("somePublicFunc()"))
        }
    }

    func testPublicExtensionOnRedundantPublicKind() {
        assertRedundantPublicAccessibility(.class("PublicExtensionOnRedundantPublicKind"))
        assertRedundantPublicAccessibility(.extensionClass("PublicExtensionOnRedundantPublicKind"))
    }

    func testPublicTypeUsedAsPublicPropertyType() {
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyType"))
        assertNotRedundantPublicAccessibility(.struct("PublicTypeUsedAsPublicPropertyGenericArgumentType"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyArrayType"))
    }

    func testPublicTypeUsedAsPublicInitializerParameterType() {
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicInitializerParameterType"))
    }

    func testPublicTypeUsedAsPublicFunctionParameterType() {
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionParameterType"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionParameterTypeClosureArgument"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionParameterTypeClosureReturnType"))
    }

    func testPublicTypeUsedAsPublicFunctionReturnType() {
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionReturnType"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionReturnTypeClosureArgument"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionReturnTypeClosureReturnType"))
    }

    func testPublicTypeUsedAsPublicSubscriptParameterType() {
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicSubscriptParameterType"))
    }

    func testPublicTypeUsedAsPublicSubscriptReturnType() {
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicSubscriptReturnType"))
    }

    func testPublicTypeUsedInPublicFunctionBody() {
        assertRedundantPublicAccessibility(.class("PublicTypeUsedInPublicFunctionBody"))
    }

    func testIgnoreCommentCommands() {
        assertNotRedundantPublicAccessibility(.class("IgnoreCommentCommand"))
        assertNotRedundantPublicAccessibility(.class("IgnoreAllCommentCommand"))
    }

    func testTestableImport() {
        assertRedundantPublicAccessibility(.class("RedundantPublicTestableImportClass")) {
            self.assertRedundantPublicAccessibility(.varInstance("testableProperty"))
        }
        assertNotRedundantPublicAccessibility(.class("NotRedundantPublicTestableImportClass"))
    }

    func testFunctionGenericParameter() {
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolA"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolB"))
    }

    func testFunctionGenericRequirement() {
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionGenericRequirement_Protocol"))
    }

    func testGenericClassParameter() {
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicClassGenericParameter_ProtocolA"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicClassGenericParameter_ProtocolB"))
    }

    func testClassGenericRequirement() {
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicClassGenericRequirement_Protocol"))
    }
}

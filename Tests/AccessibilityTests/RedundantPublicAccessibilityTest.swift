import XCTest
import Shared
@testable import TestShared
@testable import PeripheryKit

class RedundantPublicAccessibilityTest: SourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        AccessibilityProjectPath.chdir {
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

    func testPublicClassInheritingPublicClass() {
        assertNotRedundantPublicAccessibility(.class("PublicClassInheritingPublicClass_Superclass"))
        assertNotRedundantPublicAccessibility(.class("PublicClassInheritingPublicClass"))
    }

    func testPublicClassInheritingPublicExternalClass() {
        assertRedundantPublicAccessibility(.class("PublicClassInheritingPublicExternalClass"))
    }

    func testPublicClassAdoptingPublicProtocol() {
        assertRedundantPublicAccessibility(.protocol("PublicClassAdoptingPublicProtocol_Protocol"))
        assertNotRedundantPublicAccessibility(.class("PublicClassAdoptingPublicProtocol"))
    }

    func testPublicClassAdoptingInternalProtocol() {
        assertNotRedundantPublicAccessibility(.class("PublicClassAdoptingInternalProtocol"))
    }

    func testInternalClassAdoptingPublicProtocol() {
        assertRedundantPublicAccessibility(.protocol("InternalClassAdoptingPublicProtocol_Protocol"))
    }

    func testPublicProtocolRefiningPublicProtocol() {
        assertNotRedundantPublicAccessibility(.protocol("PublicProtocolRefiningPublicProtocol_Refined"))
        assertNotRedundantPublicAccessibility(.protocol("PublicProtocolRefiningPublicProtocol"))
    }

    func testInternalProtocolRefiningPublicProtocol() {
        assertRedundantPublicAccessibility(.protocol("InternalProtocolRefiningPublicProtocol_Refined"))
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

    func testEnumAssociatedValue() {
        assertNotRedundantPublicAccessibility(.enum("PublicEnumWithAssociatedValue"))
        assertNotRedundantPublicAccessibility(.struct("PublicAssociatedValueA")) {
            self.assertNotRedundantPublicAccessibility(.varInstance("value"))
        }
        assertNotRedundantPublicAccessibility(.struct("PublicAssociatedValueB")) {
            self.assertNotRedundantPublicAccessibility(.varInstance("value"))
        }
    }
}

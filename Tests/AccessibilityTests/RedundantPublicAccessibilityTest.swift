import XCTest
import Shared
@testable import TestShared
@testable import PeripheryKit

class RedundantPublicAccessibilityTest: SourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        configuration.targets = ["MainTarget", "TargetA", "TestTarget"]

        build(driver: SPMProjectDriver.self, projectPath: AccessibilityProjectPath)
    }

    func testRedundantPublicType() {
        Self.index()

        assertRedundantPublicAccessibility(.class("RedundantPublicType")) {
            self.assertRedundantPublicAccessibility(.functionMethodInstance("redundantPublicFunction()"))
        }
    }

    func testPublicDeclarationInInternalParent() {
        Self.index()

        assertNotRedundantPublicAccessibility(.class("PublicDeclarationInInternalParent")) {
            self.assertRedundantPublicAccessibility(.functionMethodInstance("somePublicFunc()"))
        }
    }

    func testPublicExtensionOnRedundantPublicKind() {
        Self.index()

        assertRedundantPublicAccessibility(.class("PublicExtensionOnRedundantPublicKind"))
        assertRedundantPublicAccessibility(.extensionClass("PublicExtensionOnRedundantPublicKind"))
    }

    func testPublicTypeUsedAsPublicPropertyType() {
        Self.index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyType1"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyType2"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyType3"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyType4"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyType5"))
        assertNotRedundantPublicAccessibility(.struct("PublicTypeUsedAsPublicPropertyGenericArgumentType"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyArrayType"))
    }

    func testPublicTypeUsedAsPublicInitializerParameterType() {
        Self.index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicInitializerParameterType"))
    }

    func testPublicTypeUsedAsPublicFunctionParameterType() {
        Self.index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionParameterType"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionParameterTypeClosureArgument"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionParameterTypeClosureReturnType"))
    }

    func testPublicTypeUsedAsPublicFunctionReturnType() {
        Self.index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionReturnType"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionReturnTypeClosureArgument"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionReturnTypeClosureReturnType"))
    }

    func testPublicTypeUsedAsPublicSubscriptParameterType() {
        Self.index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicSubscriptParameterType"))
    }

    func testPublicTypeUsedAsPublicSubscriptReturnType() {
        Self.index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicSubscriptReturnType"))
    }

    func testPublicTypeUsedInPublicFunctionBody() {
        Self.index()

        assertRedundantPublicAccessibility(.class("PublicTypeUsedInPublicFunctionBody"))
    }

    func testPublicClassInheritingPublicClass() {
        Self.index()

        assertNotRedundantPublicAccessibility(.class("PublicClassInheritingPublicClass_Superclass"))
        assertNotRedundantPublicAccessibility(.class("PublicClassInheritingPublicClass"))
    }

    func testPublicClassInheritingPublicExternalClass() {
        Self.index()

        assertRedundantPublicAccessibility(.class("PublicClassInheritingPublicExternalClass"))
    }

    func testPublicClassAdoptingPublicProtocol() {
        Self.index()

        assertRedundantPublicAccessibility(.protocol("PublicClassAdoptingPublicProtocol_Protocol"))
        assertNotRedundantPublicAccessibility(.class("PublicClassAdoptingPublicProtocol"))
    }

    #if os(macOS)
    func testPublicClassAdoptingExternalProtocolObjcAccessible() {
        configuration.retainObjcAccessible = true
        Self.index()

        assertNotRedundantPublicAccessibility(.class("PublicClassAdoptingExternalProtocolObjcAccessible")) {
            self.assertNotRedundantPublicAccessibility(.functionMethodInstance("someExternalProtocolMethod()"))
        }
    }
    #endif

    func testPublicClassAdoptingInternalProtocol() {
        Self.index()

        assertNotRedundantPublicAccessibility(.class("PublicClassAdoptingInternalProtocol"))
    }

    func testInternalClassAdoptingPublicProtocol() {
        Self.index()

        assertRedundantPublicAccessibility(.protocol("InternalClassAdoptingPublicProtocol_Protocol"))
    }

    func testPublicProtocolRefiningPublicProtocol() {
        Self.index()

        assertNotRedundantPublicAccessibility(.protocol("PublicProtocolRefiningPublicProtocol_Refined"))
        assertNotRedundantPublicAccessibility(.protocol("PublicProtocolRefiningPublicProtocol"))
    }

    func testInternalProtocolRefiningPublicProtocol() {
        Self.index()

        assertRedundantPublicAccessibility(.protocol("InternalProtocolRefiningPublicProtocol_Refined"))
    }

    func testIgnoreCommentCommands() {
        Self.index()

        assertNotRedundantPublicAccessibility(.class("IgnoreCommentCommand"))
        assertNotRedundantPublicAccessibility(.class("IgnoreAllCommentCommand"))
    }

    func testTestableImport() {
        Self.index()

        assertRedundantPublicAccessibility(.class("RedundantPublicTestableImportClass")) {
            self.assertRedundantPublicAccessibility(.varInstance("testableProperty"))
        }
        assertNotRedundantPublicAccessibility(.class("NotRedundantPublicTestableImportClass"))
    }

    func testFunctionGenericParameter() {
        Self.index()

        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolA"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolB"))
    }

    func testFunctionGenericRequirement() {
        Self.index()

        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionGenericRequirement_Protocol"))
    }

    func testGenericClassParameter() {
        Self.index()

        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicClassGenericParameter_ProtocolA"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicClassGenericParameter_ProtocolB"))
    }

    func testClassGenericRequirement() {
        Self.index()

        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicClassGenericRequirement_Protocol"))
    }

    func testEnumAssociatedValue() {
        Self.index()

        assertNotRedundantPublicAccessibility(.enum("PublicEnumWithAssociatedValue"))
        assertNotRedundantPublicAccessibility(.struct("PublicAssociatedValueA")) {
            self.assertNotRedundantPublicAccessibility(.varInstance("value"))
        }
        assertNotRedundantPublicAccessibility(.struct("PublicAssociatedValueB")) {
            self.assertNotRedundantPublicAccessibility(.varInstance("value"))
        }
    }

    func testTypealiasWithClosureType() {
        Self.index()

        assertNotRedundantPublicAccessibility(.typealias("PublicTypealiasWithClosureType"))
        assertNotRedundantPublicAccessibility(.struct("PublicTypealiasStruct"))
    }

    func testPublicTypeUsedInPublicClosure() {
        Self.index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedInPublicClosureReturnType"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedInPublicClosureInputType"))
    }

    func testFunctionMetatypeParameterUsedAsGenericReturnType() {
        Self.index()

        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType1"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType2"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType3"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType5"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType6"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType7"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType8"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType9"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType10_1"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType10_2"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType10_3"))

        // Destructured binding control.
        assertRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType4"))
    }
}

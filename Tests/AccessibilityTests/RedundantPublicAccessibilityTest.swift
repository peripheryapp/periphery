import Configuration
@testable import TestShared
import XCTest

class RedundantPublicAccessibilityTest: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        build(projectPath: AccessibilityProjectPath)
    }

    func testRedundantPublicType() {
        index()

        assertRedundantPublicAccessibility(.class("RedundantPublicType")) {
            self.assertRedundantPublicAccessibility(.functionMethodInstance("redundantPublicFunction()"))
        }
    }

    func testPublicDeclarationInInternalParent() {
        index()

        assertNotRedundantPublicAccessibility(.class("PublicDeclarationInInternalParent")) {
            self.assertRedundantPublicAccessibility(.functionMethodInstance("somePublicFunc()"))
        }
    }

    func testPublicExtensionOnRedundantPublicKind() {
        index()

        assertRedundantPublicAccessibility(.class("PublicExtensionOnRedundantPublicKind"))
        assertRedundantPublicAccessibility(.extensionClass("PublicExtensionOnRedundantPublicKind"))
    }

    func testPublicTypeUsedAsPublicPropertyType() {
        index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyType1"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyType2"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyType3"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyType4"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyType5"))
        assertNotRedundantPublicAccessibility(.struct("PublicTypeUsedAsPublicPropertyGenericArgumentType"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicPropertyArrayType"))
    }

    func testPublicTypeUsedAsPublicPropertyInitializer() {
        index()

        assertNotRedundantPublicAccessibility(.struct("PublicTypeUsedAsPublicPropertyInitializer_Simple"))
        assertNotRedundantPublicAccessibility(.struct("PublicTypeUsedAsPublicPropertyInitializer_GenericParameter"))
        assertNotRedundantPublicAccessibility(.enum("PublicTypeUsedAsPublicPropertyInitializer_ArrayLiteralEnum"))
        assertNotRedundantPublicAccessibility(.enum("PublicTypeUsedAsPublicPropertyInitializer_DictLiteralKeyEnum"))
        assertNotRedundantPublicAccessibility(.enum("PublicTypeUsedAsPublicPropertyInitializer_DictLiteralValueEnum"))
        assertNotRedundantPublicAccessibility(.enum("PublicTypeUsedAsPublicPropertyInitializer_DirectMemberAccessEnum"))
        assertNotRedundantPublicAccessibility(.enum("PublicTypeUsedAsPublicPropertyInitializer_SetLiteralEnum"))
        assertNotRedundantPublicAccessibility(.enum("PublicTypeUsedAsPublicPropertyInitializer_TernaryEnum"))
    }

    func testPublicTypeUsedAsPublicInitializerParameterType() {
        index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicInitializerParameterType"))
    }

    func testPublicTypeUsedAsPublicFunctionParameterType() {
        index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionParameterType"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionParameterTypeClosureArgument"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionParameterTypeClosureReturnType"))
    }

    func testPublicTypeUsedAsPublicFunctionParameterDefaultValue() {
        index()

        assertNotRedundantPublicAccessibility(.struct("PublicTypeUsedAsPublicFunctionParameterDefaultValue")) {
            self.assertNotRedundantPublicAccessibility(.varStatic("somePublicValue"))
        }
    }

    func testPublicTypeUsedAsPublicFunctionReturnType() {
        index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionReturnType"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionReturnTypeClosureArgument"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicFunctionReturnTypeClosureReturnType"))
    }

    func testPublicTypeUsedAsPublicSubscriptParameterType() {
        index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicSubscriptParameterType"))
    }

    func testPublicTypeUsedAsPublicSubscriptReturnType() {
        index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedAsPublicSubscriptReturnType"))
    }

    func testPublicTypeUsedInPublicFunctionBody() {
        index()

        assertRedundantPublicAccessibility(.class("PublicTypeUsedInPublicFunctionBody"))
    }

    func testPublicClassInheritingPublicClass() {
        index()

        assertNotRedundantPublicAccessibility(.class("PublicClassInheritingPublicClass_Superclass"))
        assertNotRedundantPublicAccessibility(.class("PublicClassInheritingPublicClass"))
    }

    func testPublicClassInheritingPublicExternalClass() {
        index()

        assertRedundantPublicAccessibility(.class("PublicClassInheritingPublicExternalClass"))
    }

    func testPublicClassInheritingPublicClassWithGenericRequirement() {
        index()

        assertNotRedundantPublicAccessibility(.struct("PublicClassInheritingPublicClassWithGenericParameter_GenericType"))
        assertNotRedundantPublicAccessibility(.class("PublicClassInheritingPublicClassWithGenericParameter_Superclass"))
        assertNotRedundantPublicAccessibility(.class("PublicClassInheritingPublicClassWithGenericParameter"))
    }

    func testPublicClassAdoptingPublicProtocol() {
        index()

        assertRedundantPublicAccessibility(.protocol("PublicClassAdoptingPublicProtocol_Protocol"))
        assertNotRedundantPublicAccessibility(.class("PublicClassAdoptingPublicProtocol"))
    }

    #if os(macOS)
        func testPublicClassAdoptingExternalProtocolObjcAccessible() {
            let configuration = Configuration()
            configuration.retainObjcAccessible = true
            Self.index(configuration: configuration)

            assertNotRedundantPublicAccessibility(.class("PublicClassAdoptingExternalProtocolObjcAccessible")) {
                self.assertNotRedundantPublicAccessibility(.functionMethodInstance("someExternalProtocolMethod()"))
            }
        }
    #endif

    func testPublicClassAdoptingInternalProtocol() {
        index()

        assertNotRedundantPublicAccessibility(.class("PublicClassAdoptingInternalProtocol"))
    }

    func testInternalClassAdoptingPublicProtocol() {
        index()

        assertRedundantPublicAccessibility(.protocol("InternalClassAdoptingPublicProtocol_Protocol"))
    }

    func testPublicProtocolRefiningPublicProtocol() {
        index()

        assertNotRedundantPublicAccessibility(.protocol("PublicProtocolRefiningPublicProtocol_Refined"))
        assertNotRedundantPublicAccessibility(.protocol("PublicProtocolRefiningPublicProtocol"))
    }

    func testInternalProtocolRefiningPublicProtocol() {
        index()

        assertRedundantPublicAccessibility(.protocol("InternalProtocolRefiningPublicProtocol_Refined"))
    }

    func testIgnoreCommentCommands() {
        index()

        assertNotRedundantPublicAccessibility(.class("IgnoreCommentCommand"))
        assertNotRedundantPublicAccessibility(.class("IgnoreAllCommentCommand"))
    }

    func testTestableImport() {
        index()

        assertRedundantPublicAccessibility(.class("RedundantPublicTestableImportClass")) {
            self.assertRedundantPublicAccessibility(.varInstance("testableProperty"))
        }
        assertNotRedundantPublicAccessibility(.class("NotRedundantPublicTestableImportClass"))
    }

    func testFunctionGenericParameter() {
        index()

        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolA"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolB"))
    }

    func testFunctionGenericRequirement() {
        index()

        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionGenericRequirement_Protocol"))
    }

    func testGenericClassParameter() {
        index()

        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicClassGenericParameter_ProtocolA"))
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicClassGenericParameter_ProtocolB"))
    }

    func testClassGenericRequirement() {
        index()

        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicClassGenericRequirement_Protocol"))
    }

    func testEnumAssociatedValue() {
        index()

        assertNotRedundantPublicAccessibility(.enum("PublicEnumWithAssociatedValue"))
        assertNotRedundantPublicAccessibility(.struct("PublicAssociatedValueA")) {
            self.assertNotRedundantPublicAccessibility(.varInstance("value"))
        }
        assertNotRedundantPublicAccessibility(.struct("PublicAssociatedValueB")) {
            self.assertNotRedundantPublicAccessibility(.varInstance("value"))
        }
    }

    func testEnumCaseWithParameter() {
        index()

        assertNotRedundantPublicAccessibility(.class("PublicEnumCaseWithParameter_ParameterType"))
        assertNotRedundantPublicAccessibility(.class("PublicEnumCaseWithParameter_ParameterType_Outer")) {
            self.assertNotRedundantPublicAccessibility(.class("Inner"))
        }
        assertNotRedundantPublicAccessibility(.enum("PublicEnumCaseWithParameter"))
    }

    func testTypealiasWithClosureType() {
        index()

        assertNotRedundantPublicAccessibility(.typealias("PublicTypealiasWithClosureType"))
        assertNotRedundantPublicAccessibility(.struct("PublicTypealiasStruct"))
    }

    func testPublicTypeUsedInPublicClosure() {
        index()

        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedInPublicClosureReturnType"))
        assertNotRedundantPublicAccessibility(.class("PublicTypeUsedInPublicClosureInputType"))
    }

    func testFunctionMetatypeParameterUsedAsGenericReturnType() {
        index()

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
        assertNotRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType11"))

        // Destructured binding control.
        assertRedundantPublicAccessibility(.protocol("PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType4"))
    }

    /// A public protocol that is not directly referenced cross-module may still be exposed by a public member declared
    /// within an extension that is accessed on a conforming type.
    ///
    ///     // TargetA
    ///     public protocol MyProtocol {}
    ///     public extension MyProtocol {
    ///         func someExtensionFunc() {}
    ///     }
    ///     public class MyClass: MyProtocol {}
    ///
    ///     // TargetB
    ///     let cls = MyClass()
    ///     cls.someExtensionFunc()
    ///
    func testPublicProtocolIndirectlyReferencedByExtensionMember() {
        index()

        assertNotRedundantPublicAccessibility(.protocol("ProtocolIndirectlyReferencedCrossModuleByExtensionMember"))
        assertNotRedundantPublicAccessibility(.extensionProtocol("ProtocolIndirectlyReferencedCrossModuleByExtensionMember")) {
            self.assertNotRedundantPublicAccessibility(.functionMethodInstance("somePublicFunc()"))
        }
    }

    func testPublicActor() {
        index()

        assertNotRedundantPublicAccessibility(.class("PublicActor")) {
            self.assertNotRedundantPublicAccessibility(.functionMethodInstance("someFunc()"))
        }
    }

    func testPublicWrappedProperty() {
        index()

        assertNotRedundantPublicAccessibility(.struct("PublicWrapper")) {
            self.assertNotRedundantPublicAccessibility(.varInstance("wrappedValue"))
            self.assertNotRedundantPublicAccessibility(.functionConstructor("init(wrappedValue:)"))
        }

        assertNotRedundantPublicAccessibility(.struct("PublicWrappedProperty")) {
            self.assertNotRedundantPublicAccessibility(.varInstance("wrappedProperty"))
        }
    }

    func testPublicInlinableFunction() {
        index()

        assertNotRedundantPublicAccessibility(.class("ClassReferencedFromPublicInlinableFunction"))
        assertNotRedundantPublicAccessibility(.class("ClassReferencedFromPublicInlinableFunction_UsableFromInline"))
    }

    func testPublicInheritedAssociatedType() {
        index()

        assertNotRedundantPublicAccessibility(.protocol("PublicInheritedAssociatedType"))
    }

    func testPublicAssociatedTypeDefaultType() {
        index()

        assertNotRedundantPublicAccessibility(.protocol("PublicInheritedAssociatedTypeDefaultType"))
    }

    func testPublicComparableOperatorFunction() {
        index()

        assertNotRedundantPublicAccessibility(.functionOperatorInfix("<(_:_:)"))
        assertNotRedundantPublicAccessibility(.functionOperatorInfix("==(_:_:)"))
    }
}

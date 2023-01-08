import XCTest
import SystemPackage
import Shared
@testable import TestShared
@testable import PeripheryKit

final class RetentionTest: FixtureSourceGraphTestCase {
    static override func setUp() {
        super.setUp()

        configuration.targets = ["RetentionFixtures"]

        build(driver: SPMProjectDriver.self)
    }

    func testNonReferencedClass() {
        analyze() {
            assertNotReferenced(.class("FixtureClass1"))
        }
    }

    func testNonReferencedFreeFunction() {
        analyze() {
            assertNotReferenced(.functionFree("someFunction()"))
        }
    }

    func testNonReferencedMethod() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass2")) {
                self.assertNotReferenced(.functionMethodInstance("someMethod()"))
            }
        }
    }

    func testNonReferencedProperty() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass3")) {
                self.assertNotReferenced(.varStatic("someStaticVar"))
                self.assertNotReferenced(.varInstance("someVar"))
            }
        }
    }

    func testNonReferencedMethodInClassExtension() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass4")) {
                self.assertNotReferenced(.functionMethodInstance("someMethod()"))
            }
        }
    }

    func testConformingProtocolReferencedByNonReferencedClass() {
        analyze() {
            assertNotReferenced(.class("FixtureClass6"))
            assertNotReferenced(.protocol("FixtureProtocol1"))
        }
    }

    func testSelfReferencedClass() {
        analyze() {
            assertNotReferenced(.class("FixtureClass8"))
        }
    }

    func testSelfReferencedRecursiveMethod() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass9")) {
                self.assertNotReferenced(.functionMethodInstance("recursive()"))
            }
        }
    }

    func testRetainsSelfReferencedMethodViaReceiver() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass92")) {
                self.assertReferenced(.functionMethodInstance("someFunc()"))
            }
        }
    }

    func testRetainsReferencedMethodViaReceiver() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass113")) {
                self.assertReferenced(.functionMethodStatic("make()"))
            }
        }
    }

    func testSelfReferencedProperty() {
        analyze() {
            assertNotReferenced(.class("FixtureClass39")) {
                self.assertNotReferenced(.varInstance("someVar"))
            }
        }
    }

    func testRetainsInheritedClass() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass13")) {
                self.assertReferenced(.varInstance("cls"))
            }

            assertReferenced(.class("FixtureClass11"))
            assertReferenced(.class("FixtureClass12"))
        }
    }

    func testCrossReferencedClasses() {
        analyze() {
            assertNotReferenced(.class("FixtureClass14"))
            assertNotReferenced(.class("FixtureClass15"))
            assertNotReferenced(.class("FixtureClass16"))
        }
    }

    func testDeeplyNestedClassReferences() {
        analyze() {
            assertNotReferenced(.class("FixtureClass17")) {
                self.assertNotReferenced(.class("FixtureClass18")) {
                    self.assertNotReferenced(.class("FixtureClass19"))
                }
            }
        }
    }

    func testRetainPublicMembers() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass26")) {
                self.assertReferenced(.functionMethodInstance("funcPublic()"))
                self.assertNotReferenced(.functionMethodInstance("funcPrivate()"))
                self.assertNotReferenced(.functionMethodInstance("funcInternal()"))
                self.assertReferenced(.functionMethodInstance("funcOpen()"))
            }
        }
    }

    func testConformanceToExternalProtocolIsRetained() {
        analyze() {
            // Retained because it's a method from an external declaration (in this case, Equatable)
            assertReferenced(.class("FixtureClass55")) {
                self.assertReferenced(.functionOperatorInfix("==(_:_:)"))
            }
        }
    }

    func testSimpleRedundantProtocol() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass114"))
            assertReferenced(.protocol("FixtureProtocol114"))
            assertRedundantProtocol("FixtureProtocol114",
                                    implementedBy:
                                        .class("FixtureClass114"),
                                        .extensionClass("FixtureClass115"),
                                        .struct("FixtureStruct116"))
        }
    }

    func testRedundantProtocolThatInheritsAnyObject() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass121"))
            assertReferenced(.protocol("FixtureProtocol121"))
            assertRedundantProtocol("FixtureProtocol121", implementedBy: .class("FixtureClass121"))

            assertReferenced(.class("FixtureClass122"))
            assertReferenced(.protocol("FixtureProtocol122"))
            assertRedundantProtocol("FixtureProtocol122", implementedBy: .class("FixtureClass122"))
        }
    }

    func testRedundantProtocolThatInheritsForeignProtocol() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass118"))
            assertReferenced(.protocol("FixtureProtocol118"))
            // Protocols that inherit external protocols cannot be guaranteed to be redundant.
            assertNotRedundantProtocol("FixtureProtocol118")
        }
    }

    func testProtocolUsedAsExistentialType() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass119"))
            assertReferenced(.protocol("FixtureProtocol119")) {
                self.assertNotReferenced(.functionMethodInstance("protocolFunc()"))
            }
            // Protocol is not redundant even though none of its members are called as it's used an existential type.
            assertNotRedundantProtocol("FixtureProtocol119")
        }
    }

    func testProtocolVarReferencedByProtocolMethodInSameClassIsRedundant() {
        // Despite the conforming class depending internally upon the protocol methods, the protocol
        // itself is unused. In a real situation the protocol could be removed and the conforming
        // class refactored.
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass51")) {
                self.assertReferenced(.functionMethodInstance("publicMethod()"))
                self.assertReferenced(.functionMethodInstance("protocolMethod()"))
                self.assertReferenced(.varInstance("protocolVar"))
            }
            assertReferenced(.protocol("FixtureProtocol51"))
            assertRedundantProtocol("FixtureProtocol51", implementedBy: .class("FixtureClass51"))
        }
    }

    func testProtocolMethodCalledIndirectlyByProtocolIsRetained() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass52")) {
                self.assertReferenced(.functionMethodInstance("protocolMethod()"))
            }
            assertReferenced(.protocol("FixtureProtocol52"))
        }
    }

    func testDoesNotRetainProtocolMethodInSubclassWithDefaultImplementation() {
        // Protocol witness tables are only associated with the conforming class, and do not
        // descent to subclasses. Therefore, a protocol method that's only implemented in a subclass
        // and not the parent conforming class is actually unused.
        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol83")) {
                self.assertReferenced(.functionMethodInstance("protocolMethod()"))
            }

            assertReferenced(.extensionProtocol("FixtureProtocol83")) {
                self.assertReferenced(.functionMethodInstance("protocolMethod()"))
            }

            assertReferenced(.class("FixtureClass84")) {
                self.assertNotReferenced(.functionMethodInstance("protocolMethod()"))
            }
        }
    }

    func testRetainsProtocolExtension() {
        analyze(retainPublic: true) {
            assertReferenced(.extensionProtocol("FixtureProtocol81"))
        }
    }

    func testUnusedProtocolWithExtension() {
        analyze(retainPublic: true) {
            assertNotReferenced(.protocol("FixtureProtocol82"))
            assertNotReferenced(.extensionProtocol("FixtureProtocol82"))
        }
    }

    func testRetainsProtocolMethodImplementedInExtension() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass80")) {
                self.assertReferenced(.functionMethodInstance("someMethod()"))
                self.assertReferenced(.functionMethodInstance("protocolMethodWithUnusedDefault()"))
            }
            assertReferenced(.protocol("FixtureProtocol80")) {
                self.assertReferenced(.functionMethodInstance("protocolMethod()"))
                self.assertReferenced(.functionMethodInstance("protocolMethodWithUnusedDefault()"))
            }
            assertReferenced(.extensionProtocol("FixtureProtocol80")) {
                // The protocol extension contains a default implementation but it's unused because
                // the class also implements the function. Regardless, it needs to be retained.
                self.assertReferenced(.functionMethodInstance("protocolMethodWithUnusedDefault()"))
            }
        }
    }

    func testRetainsNonProtocolMethodDefinedInProtocolExtension() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass66")) {
                self.assertReferenced(.functionMethodInstance("someMethod()"))
            }
            assertReferenced(.protocol("FixtureProtocol66")) {
                // Even though the protocol is retained because of the use of method declared
                // within the extension, the protocol method itself is not used.
                self.assertNotReferenced(.functionMethodInstance("protocolMethod()"))
            }
            assertReferenced(.extensionProtocol("FixtureProtocol66")) {
                self.assertReferenced(.functionMethodInstance("nonProtocolMethod()"))
            }
        }
    }

    func testDoesNotRetainUnusedProtocolMethodWithDefaultImplementation() {
        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol84")) {
                self.assertReferenced(.functionMethodInstance("usedMethod()"))
                self.assertNotReferenced(.functionMethodInstance("unusedMethod()"))
            }
            assertReferenced(.extensionProtocol("FixtureProtocol84")) {
                self.assertReferenced(.functionMethodInstance("usedMethod()"))
                self.assertNotReferenced(.functionMethodInstance("unusedMethod()"))
            }
        }
    }

    func testRetainedProtocolDoesNotRetainUnusedClass() {
        analyze(retainPublic: true) {
            assertNotReferenced(.class("FixtureClass57")) {
                self.assertNotReferenced(.functionMethodInstance("protocolMethod()"))
            }
            assertReferenced(.protocol("FixtureProtocol57"))
        }
    }

    func testRetainedProtocolDoesNotRetainImplementationInUnusedClass() {
        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol200")) {
                self.assertReferenced(.functionMethodInstance("protocolFunc()"))
            }
            assertNotReferenced(.class("FixtureClass200")) {
                self.assertNotReferenced(.functionMethodInstance("protocolFunc()"))
            }
            assertNotReferenced(.class("FixtureClass201"))
        }
    }

    func testRetainOverridingMethod() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass67")) {
                self.assertReferenced(.functionMethodInstance("someMethod()"))
            }
            assertReferenced(.class("FixtureClass68")) {
                self.assertReferenced(.functionMethodInstance("someMethod()"))
            }
        }
    }

    func testUnusedOverriddenMethod() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass81Base")) {
                self.assertNotReferenced(.functionMethodInstance("someMethod()"))
            }
            assertReferenced(.class("FixtureClass81Sub")) {
                self.assertReferenced(.functionMethodInstance("someMethod()"))
            }
        }
    }

    func testOverriddenMethodRetainedBySuper() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass82Base")) {
                self.assertReferenced(.functionMethodInstance("someMethod()"))
            }
            assertReferenced(.class("FixtureClass82Sub")) {
                self.assertReferenced(.functionMethodInstance("someMethod()"))
            }
        }
    }

    func testEnumCases() {
        let enumTypes = ["String", "Character", "Int", "Float", "Double", "RawRepresentable"]
        analyze(retainPublic: true) {
            assertReferenced(.enum("Fixture28Enum_Bare")) {
                self.assertReferenced(.enumelement("used"))
                self.assertNotReferenced(.enumelement("unused"))
            }

            for enumType in enumTypes {
                let enumName = "Fixture28Enum_\(enumType)"

                assertReferenced(.enum(enumName)) {
                    self.assertReferenced(.enumelement("used"))
                    self.assertReferenced(.enumelement("unused"))
                }
            }
        }
    }

    func testRetainsPublicEnumCases() {
        analyze(retainPublic: true) {
            assertReferenced(.enum("FixtureEnum179")) {
                self.assertReferenced(.enumelement("someCase"))
            }
        }
    }

    func testRetainsDestructor() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass40")) {
                self.assertReferenced(.functionDestructor("deinit"))
            }
        }
    }

    func testRetainsDefaultConstructor() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass41")) {
                self.assertReferenced(.functionConstructor("init()"))
            }
        }
    }

    func testAccessibility() {
        analyze() {
            assertAccessibility(.class("FixtureClass31"), .public) {
                self.assertAccessibility(.functionConstructor("init(arg:)"), .public)
                self.assertAccessibility(.functionMethodInstance("openFunc()"), .open)

                self.assertAccessibility(.class("FixtureClass31Inner"), .public) {
                    self.assertAccessibility(.functionMethodInstance("privateFunc()"), .private)
                }
            }

            assertAccessibility(.class("FixtureClass32"), .private) {
                self.assertAccessibility(.varInstance("publicVar"), .public)
            }

            assertAccessibility(.class("FixtureClass33"), .internal)

            assertAccessibility(.enum("Enum1"), .internal) {
                self.assertAccessibility(.functionMethodInstance("publicEnumFunc()"), .public)
            }

            assertAccessibility(.class("FixtureClass50"), .public) {
                self.assertAccessibility(.functionMethodInstance("publicMethodInExtension()"), .public)
                self.assertAccessibility(.functionMethodInstance("methodInPublicExtension()"), .public)
                self.assertAccessibility(.functionMethodStatic("staticMethodInPublicExtension()"), .public)
                self.assertAccessibility(.varStatic("staticVarInExtension"), .public)
                self.assertAccessibility(.functionMethodInstance("privateMethodInPublicExtension()"), .private)
                self.assertAccessibility(.functionMethodInstance("internalMethodInPublicExtension()"), .internal)
            }

            assertAccessibility(.extensionStruct("Array"), .public) {
                self.assertAccessibility(.functionMethodInstance("methodInExternalStructTypeExtension()"), .public)
            }

            assertAccessibility(.extensionProtocol("Sequence"), .public) {
                self.assertAccessibility(.functionMethodInstance("methodInExternalProtocolTypeExtension()"), .public)
            }

            assertAccessibility(.extensionStruct("Name"), .public) {
                self.assertAccessibility(.varStatic("CustomNotification"), .public)
            }
        }
    }

    func testXCTestCaseClassesAndMethodsAreRetained() {
        analyze() {
            assertReferenced(.class("FixtureClass34")) {
                self.assertReferenced(.functionMethodInstance("testSomething()"))
                self.assertReferenced(.functionMethodInstance("setUp()"))
                self.assertReferenced(.functionMethodStatic("setUp()"))
            }
            assertReferenced(.class("FixtureClass34Subclass")) {
                self.assertReferenced(.functionMethodInstance("testSubclass()"))
            }
        }
    }

    func testRetainsMethodDefinedInExtensionOnStandardType() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass35")) {
                self.assertReferenced(.functionMethodInstance("testSomething()"))
            }
            assertReferenced(.extensionStruct("String")) {
                self.assertReferenced(.varInstance("trimmed"))
            }
        }
    }

    func testRetainsGenericType() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass37"))
            assertReferenced(.protocol("FixtureProtocol37"))
        }
    }

    func testUnusedTypealias() {
        analyze() {
            assertNotReferenced(.typealias("UnusedAlias"))
        }
    }

    func testRetainsConstructorOfGenericClassAndStruct() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass61")) {
                self.assertReferenced(.functionConstructor("init(someVar:)"))
            }
            assertReferenced(.struct("FixtureStruct61")) {
                self.assertReferenced(.functionConstructor("init(someVar:)"))
            }
        }
    }

    func testFunctionAccessorsRetainReferences() {
        configuration.retainAssignOnlyProperties = true

        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass63")) {
                self.assertReferenced(.varInstance("referencedByGetter"))
                self.assertReferenced(.varInstance("referencedBySetter"))
                self.assertReferenced(.varInstance("referencedByDidSet"))
            }
        }
    }

    func testAssignOnlyPropertyAnalysisDoesNotApplyToProtocolProperties() {
        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol124")) {
                self.assertReferenced(.varInstance("someProperty"))
            }
            assertReferenced(.class("FixtureClass124")) {
                self.assertReferenced(.varInstance("someProperty"))
            }
        }
    }

    func testPropertyReferencedByComputedValue() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass78")) {
                self.assertReferenced(.varInstance("someVar"))
                self.assertReferenced(.varInstance("someOtherVar"))
                self.assertNotReferenced(.varInstance("unusedVar"))
            }
        }
    }

    func testInstanceVarReferencedInClosure() {
        configuration.retainAssignOnlyProperties = true

        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass69")) {
                self.assertReferenced(.varInstance("someVar"))
            }
        }
    }

    func testCodingKeyEnum() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass74")) {
                self.assertReferenced(.enum("CodingKeys"))
            }
            assertReferenced(.class("FixtureClass75")) {
                self.assertReferenced(.enum("CodingKeys"))
            }
            assertReferenced(.class("FixtureClass203")) {
                self.assertReferenced(.enum("CodingKeys"))
            }
            assertReferenced(.class("FixtureClass111")) {
                self.assertReferenced(.enum("CodingKeys"))
            }
            assertReferenced(.class("FixtureClass76")) {
                // Not referenced because the enclosing class does not conform to Codable.
                self.assertNotReferenced(.enum("CodingKeys"))
            }
          assertReferenced(.struct("FixtureClass120")) {
              self.assertReferenced(.enum("CodingKeys"))
          }
        }
    }

    func testRequiredInitInSubclass() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass77Base")) {
                self.assertReferenced(.functionConstructor("init(a:)"))
                self.assertReferenced(.functionConstructor("init(b:)"))
            }
            assertReferenced(.class("FixtureClass77")) {
                self.assertReferenced(.functionConstructor("init(a:)"))
                self.assertReferenced(.functionConstructor("init(b:)"))
                self.assertReferenced(.functionConstructor("init(c:)"))
            }
        }
    }

    func testRetainsExternalTypeExtension() {
        analyze() {
            assertReferenced(.extensionProtocol("Sequence"))
            assertReferenced(.extensionStruct("Array"))
            assertReferenced(.extensionClass("NumberFormatter"))
        }
    }

    func testRetainsInferredAssociatedType() {
        analyze(retainPublic: true) {
            assertReferenced(.struct("FixtureStruct120")) {
                self.assertReferenced(.enum("AssociatedType"))
            }
            assertReferenced(.protocol("FixtureProtocol120")) {
                self.assertReferenced(.associatedtype("AssociatedType"))
            }
        }
    }

    func testRetainsAssociatedTypeTypeAlias() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass87Usage")) {
                self.assertReferenced(.functionMethodInstance("somePublicFunction()"))
            }
            assertReferenced(.class("Fixture87StateMachine")) {
                self.assertReferenced(.functionMethodInstance("someFunction(_:)"))
            }
            assertReferenced(.struct("Fixture87AssociatedType"))
            assertReferenced(.protocol("Fixture87State")) {
                self.assertReferenced(.associatedtype("AssociatedType"))
            }
            assertReferenced(.enum("Fixture87MyState")) {
                self.assertReferenced(.typealias("AssociatedType"))
            }
        }
    }

    func testRetainsExternalAssociatedTypeTypeAlias() {
        analyze(retainPublic: true) {
            assertReferenced(.struct("Fixture110")) {
                self.assertReferenced(.typealias("Value"))
            }
        }
    }

    func testUnusedAssociatedType() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass88Usage")) {
                self.assertReferenced(.functionMethodInstance("somePublicFunction()"))
            }
            assertReferenced(.class("Fixture88StateMachine")) {
                self.assertReferenced(.functionMethodInstance("someFunction()"))
            }
            assertReferenced(.protocol("Fixture88State")) {
                self.assertNotReferenced(.associatedtype("AssociatedType"))
            }
            assertReferenced(.enum("Fixture88MyState")) {
                self.assertNotReferenced(.typealias("AssociatedType"))
            }
        }
    }

    func testIsolatedCyclicRootReferences() {
        analyze(retainPublic: true) {
            assertNotReferenced(.class("FixtureClass90"))
            assertNotReferenced(.class("FixtureClass91"))
        }
    }

    func testRetainsUsedProtocolThatInheritsForeignProtocol() {
        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol96")) {
                self.assertReferenced(.varInstance("usedValue"))
                self.assertNotReferenced(.varInstance("unusedValue"))
            }
            assertReferenced(.extensionProtocol("FixtureProtocol96")) {
                self.assertReferenced(.functionOperatorInfix("<(_:_:)"))
            }
            assertReferenced(.class("FixtureClass96")) {
                self.assertReferenced(.varInstance("usedValue"))
                self.assertNotReferenced(.varInstance("unusedValue"))
            }
        }
    }

    func testRetainsProtocolMethodsImplementedInSuperclasss() {
        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol97")) {
                self.assertReferenced(.functionMethodInstance("someProtocolMethod1()"))
                self.assertReferenced(.functionMethodInstance("someProtocolMethod2()"))
                self.assertReferenced(.varInstance("someProtocolVar"))
                self.assertNotReferenced(.functionMethodInstance("someUnusedProtocolMethod()"))
            }
            assertReferenced(.class("FixtureClass97"))
            assertReferenced(.class("FixtureClass97Base1")) {
                self.assertReferenced(.functionMethodInstance("someProtocolMethod1()"))
                self.assertReferenced(.varInstance("someProtocolVar"))
            }
            assertReferenced(.class("FixtureClass97Base2")) {
                self.assertReferenced(.functionMethodInstance("someProtocolMethod2()"))
                self.assertNotReferenced(.functionMethodInstance("someUnusedProtocolMethod()"))
            }
        }
    }

    func testProtocolMethodsImplementedOnlyInExtension() {
        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol115"))
            assertNotRedundantProtocol("FixtureProtocol115")
            assertReferenced(.extensionProtocol("FixtureProtocol115")) {
                self.assertReferenced(.functionMethodInstance("used()"))
                self.assertNotReferenced(.functionMethodInstance("unused()"))
            }
        }
    }

    func testPublicProtocolMethodImplementedOnlyInExtension() {
        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol116"))
            assertNotRedundantProtocol("FixtureProtocol116")
            assertReferenced(.extensionProtocol("FixtureProtocol116")) {
                self.assertReferenced(.functionMethodInstance("used()"))
                self.assertNotReferenced(.functionMethodInstance("unused()"))
            }
        }
    }

    func testProtocolImplementInClassAndExtension() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass98")) {
                self.assertReferenced(.functionMethodInstance("method1()"))
                self.assertReferenced(.functionMethodInstance("method2()"))
            }
            assertReferenced(.protocol("FixtureProtocol98")) {
                self.assertReferenced(.functionMethodInstance("method1()"))
                self.assertReferenced(.functionMethodInstance("method2()"))
            }
        }
    }

    func testDoesNotRetainProtocolMembersImplementedByExternalType() {
        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol110")) {
                self.assertReferenced(.functionMethodInstance("sync(execute:)"))
                self.assertNotReferenced(.functionMethodInstance("async(execute:)"))
                self.assertReferenced(.functionMethodInstance("customImplementedByExtensionUsed()"))
                self.assertNotReferenced(.functionMethodInstance("customImplementedByExtensionUnused()"))
            }
            assertReferenced(.extensionProtocol("FixtureProtocol110")) {
                self.assertReferenced(.functionMethodInstance("customImplementedByExtensionUsed()"))
                self.assertNotReferenced(.functionMethodInstance("customImplementedByExtensionUnused()"))
            }
            assertReferenced(.extensionClass("DispatchQueue")) {
                // Unused because DispatchQueue already provides an implementation, it appears Swift
                // always favors the original implementation.
                self.assertNotReferenced(.functionMethodInstance("sync(execute:)"))
                self.assertNotReferenced(.functionMethodInstance("async(execute:)"))
                self.assertReferenced(.functionMethodInstance("customImplementedByExtensionUsed()"))
                self.assertNotReferenced(.functionMethodInstance("customImplementedByExtensionUnused()"))
            }
        }
    }

    func testDoesNotRetainDescendantsOfUnusedDeclaration() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass99Outer")) {
                self.assertNotReferenced(.class("FixtureClass99")) {
                    self.assertNotReferenced(.functionMethodInstance("someMethod()"))
                    self.assertNotReferenced(.varInstance("someVar"))
                }
            }
        }
    }

    func testNestedDeclarations() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass102")) {
                self.assertReferenced(.functionMethodInstance("nested1()"))
                self.assertReferenced(.functionMethodInstance("nested2()"))
            }
        }
    }

    func testIdenticallyNamedVarsInStaticAndInstanceScopes() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass95")) {
                self.assertReferenced(.varInstance("someVar"))
                self.assertReferenced(.varStatic("someVar"))
            }
        }
    }

    func testProtocolConformingMembersAreRetained() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass27")) {
                self.assertReferenced(.functionMethodInstance("protocolMethod()"))
                self.assertReferenced(.functionMethodClass("staticProtocolMethod()"))
                self.assertReferenced(.varClass("staticProtocolVar"))
            }
            assertReferenced(.protocol("FixtureProtocol27"))
            assertReferenced(.class("FixtureClass28")) {
                self.assertReferenced(.functionMethodStatic("overrideStaticProtocolMethod()"))
                self.assertReferenced(.varStatic("overrideStaticProtocolVar"))
            }
            assertReferenced(.class("FixtureClass28Base")) {
                self.assertReferenced(.functionMethodClass("overrideStaticProtocolMethod()"))
                self.assertReferenced(.varClass("overrideStaticProtocolVar"))
            }
            assertReferenced(.protocol("FixtureProtocol28"))
        }
    }

    func testProtocolConformedByStaticMethodOutsideExtension() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass64")) // public
            assertReferenced(.class("FixtureClass65")) // retained by FixtureClass64
            assertReferenced(.functionOperatorInfix("==(_:_:)")) // Equatable
        }
    }

    func testClassRetainedByUnusedInstanceVariable() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass71")) {
                self.assertNotReferenced(.varInstance("someVar"))
            }
            assertNotReferenced(.class("FixtureClass72"))
        }
    }

    func testStaticPropertyDeclaredWithCompositeValuesIsNotRetained() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass38")) {
                self.assertNotReferenced(.varStatic("propertyA"))
                self.assertNotReferenced(.varStatic("propertyB"))
            }
        }
    }

    func testRetainImplicitDeclarations() {
        analyze(retainPublic: true) {
            assertReferenced(.struct("FixtureStruct2")) {
                self.assertReferenced(.functionConstructor("init(someVar:)"))
            }
        }
    }

    func testRetainsPropertyWrappers() {
        analyze(retainPublic: true) {
            assertReferenced(.class("Fixture111")) {
                self.assertReferenced(.varInstance("someVar"))
                self.assertReferenced(.functionMethodStatic("buildBlock()"))
            }
            assertReferenced(.class("Fixture111Wrapper")) {
                self.assertReferenced(.varInstance("wrappedValue"))
                self.assertReferenced(.varInstance("projectedValue"))
            }
        }
    }

    func testRetainsStringInterpolationAppendInterpolation() {
        analyze(retainPublic: true) {
            assertReferenced(.extensionStruct("DefaultStringInterpolation")) {
                self.assertReferenced(.functionMethodInstance("appendInterpolation(test:)"))
            }
        }
    }

    func testIgnoreComments() {
        analyze(retainPublic: true) {
            assertReferenced(.class("Fixture113")) {
                self.assertReferenced(.functionMethodInstance("someFunc(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }
            }
            assertReferenced(.class("Fixture114")) {
                self.assertReferenced(.functionMethodInstance("referencedFunc()"))
                self.assertReferenced(.functionMethodInstance("someFunc(a:b:c:)")) {
                    self.assertReferenced(.varParameter("b"))
                    self.assertReferenced(.varParameter("c"))
                }
                self.assertReferenced(.functionMethodInstance("protocolFunc(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }
            }
            assertReferenced(.protocol("Fixture114Protocol")) {
                self.assertReferenced(.functionMethodInstance("protocolFunc(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }
            }
            assertReferenced(.class("FixtureClass116")) {
                self.assertReferenced(.functionMethodInstance("someFunc()"))
                self.assertReferenced(.varInstance("simpleProperty"))
                self.assertReferenced(.varInstance("tuplePropertyA"))
                self.assertReferenced(.varInstance("tuplePropertyB"))
                self.assertReferenced(.varInstance("multiBindingPropertyA"))
                self.assertReferenced(.varInstance("multiBindingPropertyB"))
                self.assertReferenced(.varInstance("assignOnlyProperty"))
                self.assertNotAssignOnlyProperty(.varInstance("assignOnlyProperty"))
            }
            assertReferenced(.class("FixtureClass212")) {
                self.assertReferenced(.functionMethodInstance("protocolFunc(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }
            }
            assertReferenced(.class("FixtureClass213")) {
                self.assertReferenced(.functionMethodInstance("someFunc(a:b:c:)")) {
                    self.assertReferenced(.varParameter("b"))
                    self.assertReferenced(.varParameter("c"))
                }
            }
            assertReferenced(.class("Fixture205"))
            assertReferenced(.protocol("Fixture205Protocol"))
            assertNotRedundantProtocol("Fixture205Protocol")
        }
    }

    func testIgnoreAllComment() {
        analyze(retainPublic: true) {
            assertReferenced(.class("Fixture115")) {
                self.assertReferenced(.functionMethodInstance("someFunc(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }
            }
            assertReferenced(.class("Fixture116"))
        }
    }

    func testRetainsProtocolsViaCompositeTypealias() {
        analyze(retainPublic: true) {
            assertReferenced(.protocol("Fixture200"))
            assertReferenced(.protocol("Fixture201"))
            assertReferenced(.typealias("Fixture202"))
        }
    }

    func testRetainsEncodableProperties() {
        let configuration = Configuration.shared
        // CustomStringConvertible doesn't actually inherit Encodable, we're just using it because we don't have an
        // external module in which to declare our own type.
        configuration.externalEncodableProtocols = ["CustomStringConvertible"]

        analyze(retainPublic: true) {
            self.assertReferenced(.class("FixtureClass204")) {
                self.assertReferenced(.varInstance("someVar"))
            }

            self.assertReferenced(.class("FixtureClass205")) {
                self.assertReferenced(.varInstance("someVar"))
            }

            self.assertReferenced(.class("FixtureClass206")) {
                self.assertReferenced(.varInstance("someVar"))
            }

            self.assertReferenced(.class("FixtureClass207")) {
                self.assertReferenced(.varInstance("someVar"))
            }

            self.assertReferenced(.class("FixtureClass208")) {
                self.assertReferenced(.varInstance("someVar"))
            }

            self.assertReferenced(.class("FixtureClass209")) {
                self.assertReferenced(.varInstance("someVar"))
            }

            self.assertReferenced(.class("FixtureClass210")) {
                self.assertReferenced(.varInstance("someVar"))
            }
        }
    }

    func testCircularTypeInheritance() {
        analyze {
            // Intentionally blank.
            // Fixture contains a circular reference that shouldn't cause a stack overflow.
        }
    }

    func testRetainsResultBuilderMethods() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass130")) {
                self.assertReferenced(.functionMethodStatic("buildExpression(_:)"))
                self.assertReferenced(.functionMethodStatic("buildOptional(_:)"))
                self.assertReferenced(.functionMethodStatic("buildEither(first:)"))
                self.assertReferenced(.functionMethodStatic("buildEither(second:)"))
                self.assertReferenced(.functionMethodStatic("buildArray(_:)"))
                self.assertReferenced(.functionMethodStatic("buildBlock(_:)"))
                self.assertReferenced(.functionMethodStatic("buildFinalResult(_:)"))
                self.assertReferenced(.functionMethodStatic("buildLimitedAvailability(_:)"))
            }
        }
    }

    func testRetainsCallAsFunction() {
        analyze(retainPublic: true) {
            assertReferenced(.struct("FixtureStruct1")) {
                self.assertReferenced(.functionMethodInstance("callAsFunction(_:)"))
            }
        }
    }

    func testLetShorthandSyntax() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass117")) {
                self.assertReferenced(.varInstance("simpleProperty"))
                self.assertReferenced(.varInstance("guardedSimpleProperty"))
                self.assertNotAssignOnlyProperty(.varInstance("simpleProperty"))

                self.assertReferenced(.varInstance("complexProperty"))
                self.assertReferenced(.varInstance("propertyReferencedFromExtension"))
                self.assertReferenced(.varInstance("computedPropertyInExtension"))
                self.assertReferenced(.varInstance("propertyReferencedFromNestedFunction"))
                self.assertReferenced(.varInstance("propertyReferencedFromPropertyAccessor"))
            }

            // This property should be referenced, but the let shorthand workaround doesn't
            // handle properties at global (file) scope. This will remain broken until the
            // issue is resolved in Swift: https://github.com/apple/swift/issues/61509.
            self.assertNotReferenced(.varGlobal("fixtureClass117StaticProperty"))
        }
    }

    func testDoesNotRetainLazyProperty() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass36")) {
                self.assertNotReferenced(.varInstance("someLazyVar"))
                self.assertNotReferenced(.varInstance("someVar"))
            }
        }
    }

    // MARK: - Assign-only properties

    func testSimplePropertyAssignedButNeverRead() {
        configuration.retainAssignOnlyProperties = false

        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass70")) {
                self.assertNotReferenced(.varInstance("simpleUnreadVar"))
                self.assertAssignOnlyProperty(.varInstance("simpleUnreadVar"))

                self.assertNotReferenced(.varInstance("simpleUnreadShadowedVar"))
                self.assertAssignOnlyProperty(.varInstance("simpleUnreadShadowedVar"))

                self.assertNotReferenced(.varInstance("simpleUnreadVarAssignedMultiple"))
                self.assertAssignOnlyProperty(.varInstance("simpleUnreadVarAssignedMultiple"))

                self.assertNotReferenced(.varStatic("simpleStaticUnreadVar"))
                self.assertAssignOnlyProperty(.varStatic("simpleStaticUnreadVar"))

                self.assertReferenced(.varInstance("complexUnreadVar1"))
                self.assertNotAssignOnlyProperty(.varInstance("complexUnreadVar1"))

                self.assertReferenced(.varInstance("complexUnreadVar2"))
                self.assertNotAssignOnlyProperty(.varInstance("complexUnreadVar2"))

                self.assertReferenced(.varInstance("readVar"))
                self.assertNotAssignOnlyProperty(.varInstance("readVar"))

                self.assertReferenced(.varInstance("ignoredSimpleUnreadVar"))
                self.assertNotAssignOnlyProperty(.varInstance("ignoredSimpleUnreadVar"))
            }
        }

        configuration.retainAssignOnlyProperties = true

        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass70")) {
                self.assertReferenced(.varInstance("simpleUnreadVar"))
                self.assertNotAssignOnlyProperty(.varInstance("simpleUnreadVar"))

                self.assertReferenced(.varInstance("simpleUnreadShadowedVar"))
                self.assertNotAssignOnlyProperty(.varInstance("simpleUnreadShadowedVar"))

                self.assertReferenced(.varInstance("simpleUnreadVarAssignedMultiple"))
                self.assertNotAssignOnlyProperty(.varInstance("simpleUnreadVarAssignedMultiple"))

                self.assertReferenced(.varStatic("simpleStaticUnreadVar"))
                self.assertNotAssignOnlyProperty(.varStatic("simpleStaticUnreadVar"))

                self.assertReferenced(.varInstance("complexUnreadVar1"))
                self.assertNotAssignOnlyProperty(.varInstance("complexUnreadVar1"))

                self.assertReferenced(.varInstance("complexUnreadVar2"))
                self.assertNotAssignOnlyProperty(.varInstance("complexUnreadVar2"))

                self.assertReferenced(.varInstance("readVar"))
                self.assertNotAssignOnlyProperty(.varInstance("readVar"))

                self.assertReferenced(.varInstance("ignoredSimpleUnreadVar"))
                self.assertNotAssignOnlyProperty(.varInstance("ignoredSimpleUnreadVar"))
            }
        }
    }

    func testSimpleAssignOnlyPropertyNameConflict() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass131")) {
                self.assertNotReferenced(.varInstance("someProperty"))
                self.assertReferenced(.varStatic("someProperty"))
            }
        }
    }

    func testRetainsAssignOnlyPropertyTypes() {
        configuration.retainAssignOnlyProperties = false
        configuration.retainAssignOnlyPropertyTypes = ["CustomType", "(CustomType, String)", "Swift.Double"]

        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass123")) {
                self.assertReferenced(.varInstance("retainedSimpleProperty"))
                self.assertReferenced(.varInstance("retainedModulePrefixedProperty"))
                self.assertReferenced(.varInstance("retainedTupleProperty"))
                self.assertReferenced(.varInstance("retainedDestructuredPropertyA"))
                self.assertReferenced(.varInstance("retainedMultipleBindingPropertyA"))

                #if canImport(Combine)
                self.assertReferenced(.varInstance("retainedAnyCancellable"))
                #endif

                self.assertNotReferenced(.varInstance("notRetainedSimpleProperty"))
                self.assertNotReferenced(.varInstance("notRetainedModulePrefixedProperty"))
                self.assertNotReferenced(.varInstance("notRetainedTupleProperty"))
                self.assertNotReferenced(.varInstance("notRetainedDestructuredPropertyB"))
                self.assertNotReferenced(.varInstance("notRetainedMultipleBindingPropertyB"))
            }
        }
    }

    // MARK: - Unused Parameters

    func testRetainsParamUsedInOverriddenMethod() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass101Base")) {
                // Not used and not overridden.
                self.assertReferenced(.functionMethodInstance("func1(param:)")) {
                    self.assertNotReferenced(.varParameter("param"))
                }

                // The param is used.
                self.assertReferenced(.functionMethodInstance("func2(param:)")) {
                    self.assertUsedParameter("param")
                }

                // Used in override.
                self.assertReferenced(.functionMethodInstance("func3(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }

                // Used in override.
                // func4(param: String)
                self.assertReferenced(.functionMethodInstance("func4(param:)", line: 14)) {
                    self.assertReferenced(.varParameter("param"))
                }

                // Not used in any function.
                // func4(param: Int)
                self.assertReferenced(.functionMethodInstance("func4(param:)", line: 17)) {
                    self.assertNotReferenced(.varParameter("param"))
                }

                // Not used in any function.
                self.assertReferenced(.functionMethodInstance("func5(param:)")) {
                    self.assertNotReferenced(.varParameter("param"))
                }

                // Overridden in multiple subclass branches.
                self.assertReferenced(.functionMethodInstance("func7(param1:param2:)")) {
                    self.assertReferenced(.varParameter("param1"))
                    self.assertNotReferenced(.varParameter("param2"))
                }
            }

            assertReferenced(.class("FixtureClass101Subclass1")) {
                // Used in base.
                self.assertReferenced(.functionMethodInstance("func2(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }

                // The param is used.
                self.assertReferenced(.functionMethodInstance("func3(param:)")) {
                    self.assertUsedParameter("param")
                }

                // Not used in any function.
                // func4(param: Int)
                self.assertReferenced(.functionMethodInstance("func4(param:)", line: 36)) {
                    self.assertNotReferenced(.varParameter("param"))
                }

                // Overridden in multiple subclass branches.
                self.assertReferenced(.functionMethodInstance("func7(param1:param2:)")) {
                    self.assertUsedParameter("param1")
                    self.assertNotReferenced(.varParameter("param2"))
                }
            }

            assertReferenced(.class("FixtureClass101Subclass2")) {
                // The param is used.
                // func4(param: String)
                self.assertReferenced(.functionMethodInstance("func4(param:)", line: 44)) {
                    self.assertUsedParameter("param")
                }

                // Not used in any function.
                // func4(param: Int)
                self.assertReferenced(.functionMethodInstance("func4(param:)", line: 48)) {
                    self.assertNotReferenced(.varParameter("param"))
                }

                // Not used in any function.
                self.assertReferenced(.functionMethodInstance("func5(param:)")) {
                    self.assertNotReferenced(.varParameter("param"))
                }

                // Overridden in multiple subclass branches.
                self.assertReferenced(.functionMethodInstance("func7(param1:param2:)")) {
                    self.assertReferenced(.varParameter("param1"))
                    self.assertNotReferenced(.varParameter("param2"))
                }
            }

            assertReferenced(.class("FixtureClass101Subclass3")) {
                // Overridden in multiple subclass branches.
                self.assertReferenced(.functionMethodInstance("func7(param1:param2:)")) {
                    self.assertReferenced(.varParameter("param1"))
                    self.assertNotReferenced(.varParameter("param2"))
                }
            }

            assertReferenced(.class("FixtureClass101InheritForeignBase")) {
                // Overrides foreign function.
                self.assertReferenced(.functionMethodInstance("isEqual(_:)")) {
                    self.assertReferenced(.varParameter("object"))
                }
            }

            assertReferenced(.class("FixtureClass101InheritForeignSubclass1")) {
                // Overrides foreign function.
                self.assertReferenced(.functionMethodInstance("isEqual(_:)")) {
                    self.assertReferenced(.varParameter("object"))
                }
            }
        }
    }

    func testRetainsForeignProtocolParametersInSubclass() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass109")) {
                self.assertReferenced(.functionMethodInstance("copy(with:)")) {
                    self.assertReferenced(.varParameter("zone"))
                }
            }
            assertReferenced(.class("FixtureClass109Subclass")) {
                self.assertReferenced(.functionMethodInstance("copy(with:)")) {
                    self.assertReferenced(.varParameter("zone"))
                }
            }
        }
    }

    func testRetainsForeignProtocolParameters() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass103")) {
                self.assertReferenced(.functionConstructor("init(from:)")) {
                    self.assertReferenced(.varParameter("decoder"))
                }
            }
            assertReferenced(.class("FixtureClass103")) {
                self.assertReferenced(.functionMethodInstance("encode(to:)")) {
                    self.assertReferenced(.varParameter("encoder"))
                }
            }
        }
    }

    func testRetainUnusedProtocolFuncParams() {
        configuration.retainUnusedProtocolFuncParams = true

        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol107")) {
                self.assertReferenced(.functionMethodInstance("myFunc(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }
            }
            assertReferenced(.extensionProtocol("FixtureProtocol107")) {
                self.assertReferenced(.functionMethodInstance("myFunc(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }
            }
            assertReferenced(.class("FixtureClass107Class1")) {
                self.assertReferenced(.functionMethodInstance("myFunc(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }
            }
            assertReferenced(.class("FixtureClass107Class2")) {
                self.assertReferenced(.functionMethodInstance("myFunc(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }
            }
        }
    }

    func testRetainsProtocolParameters() {
        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol104")) {
                // Used in a conformance.
                self.assertReferenced(.functionMethodInstance("func1(param1:param2:)")) {
                    self.assertReferenced(.varParameter("param1"))
                }

                // Not used in any conformance.
                self.assertReferenced(.functionMethodInstance("func1(param1:param2:)")) {
                    self.assertNotReferenced(.varParameter("param2"))
                }

                // Not used in any conformance.
                self.assertReferenced(.functionMethodInstance("func2(param:)")) {
                    self.assertNotReferenced(.varParameter("param"))
                }

                // Used in the extension.
                self.assertReferenced(.functionMethodInstance("func3(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }

                // Unused in extension, but used in conformance.
                // func4(param: String)
                self.assertReferenced(.functionMethodInstance("func4(param:)", line: 11)) {
                    self.assertReferenced(.varParameter("param"))
                }

                // Unused.
                // func4(param: Int)
                self.assertReferenced(.functionMethodInstance("func4(param:)", line: 13)) {
                    self.assertNotReferenced(.varParameter("param"))
                }

                // Used in a conformance.
                self.assertReferenced(.functionMethodStatic("func5(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }

                // Used in a override.
                self.assertReferenced(.functionMethodInstance("func6(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }
            }

            assertReferenced(.extensionProtocol("FixtureProtocol104")) {
                // The param is used.
                self.assertReferenced(.functionMethodInstance("func3(param:)")) {
                    self.assertUsedParameter("param")
                }

                // Used in a conformance by another class.
                // func4(param: String)
                self.assertReferenced(.functionMethodInstance("func4(param:)", line: 27)) {
                    self.assertReferenced(.varParameter("param"))
                }

                // Unused.
                // func4(param: Int)
                self.assertReferenced(.functionMethodInstance("func4(param:)", line: 28)) {
                    self.assertNotReferenced(.varParameter("param"))
                }
            }

            assertReferenced(.class("FixtureClass104Class1")) {
                // Used in a conformance by another class.
                self.assertReferenced(.functionMethodInstance("func1(param1:param2:)")) {
                    self.assertReferenced(.varParameter("param1"))
                }

                // Not used in any conformance.
                self.assertReferenced(.functionMethodInstance("func1(param1:param2:)")) {
                    self.assertNotReferenced(.varParameter("param2"))
                }

                // Not used in any conformance.
                self.assertReferenced(.functionMethodInstance("func2(param:)")) {
                    self.assertNotReferenced(.varParameter("param"))
                }

                // The param is used.
                self.assertReferenced(.functionMethodStatic("func5(param:)")) {
                    self.assertUsedParameter("param")
                }

                // Used in a override.
                self.assertReferenced(.functionMethodInstance("func6(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }

                // The param is explicitly ignored.
                self.assertReferenced(.functionMethodInstance("func7(_:)")) {
                    self.assertUsedParameter("_")
                }
            }

            assertReferenced(.class("FixtureClass104Class2")) {
                // The param is used.
                self.assertReferenced(.functionMethodInstance("func1(param1:param2:)")) {
                    self.assertUsedParameter("param1")
                }

                // Not used in any conformance.
                self.assertReferenced(.functionMethodInstance("func1(param1:param2:)")) {
                    self.assertNotReferenced(.varParameter("param2"))
                }

                // Not used in any conformance.
                self.assertReferenced(.functionMethodInstance("func2(param:)")) {
                    self.assertNotReferenced(.varParameter("param"))
                }

                // The param is used.
                // func4(param: String)
                self.assertReferenced(.functionMethodInstance("func4(param:)", line: 50)) {
                    self.assertUsedParameter("param")
                }

                // Unused.
                // func4(param: Int)
                self.assertReferenced(.functionMethodInstance("func4(param:)", line: 54)) {
                    self.assertNotReferenced(.varParameter("param"))
                }

                // The param is used.
                self.assertReferenced(.functionMethodStatic("func5(param:)")) {
                    self.assertUsedParameter("param")
                }

                // Used in a override.
                self.assertReferenced(.functionMethodInstance("func6(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }

                // The param is explicitly ignored.
                self.assertReferenced(.functionMethodInstance("func7(_:)")) {
                    self.assertUsedParameter("_")
                }
            }

            assertReferenced(.class("FixtureClass104Class3")) {
                // The param is used.
                self.assertReferenced(.functionMethodInstance("func6(param:)")) {
                    self.assertUsedParameter("param")
                }
            }
        }
    }

    func testRetainsOpenClassParameters() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass112")) {
                self.assertReferenced(.functionMethodInstance("doSomething(with:)")) {
                    self.assertReferenced(.varParameter("value"))
                }
            }
        }
    }

    func testIgnoreUnusedParamInUnusedFunction() {
        analyze() {
            assertNotReferenced(.class("FixtureClass105")) {
                self.assertNotReferenced(.functionMethodInstance("unused(param:)")) {
                    self.assertNotReferenced(.varParameter("param"))
                }
            }
        }
    }

    func testRetainsFunctionParametersOnProtocolMembersImplementedByExternalType() {
        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol125")) {
                self.assertReferenced(.functionMethodInstance("object(forKey:)")) {
                    self.assertReferenced(.varParameter("key"))
                }
            }
        }
    }

    func testRetainsFunctionParametersOnUnimplementedProtocolMembers() {
        analyze(retainPublic: true) {
            assertReferenced(.protocol("FixtureProtocol126")) {
                self.assertReferenced(.functionMethodInstance("unimplementedFunc(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }
            }
            assertReferenced(.extensionProtocol("FixtureProtocol126")) {
                self.assertReferenced(.functionMethodInstance("unimplementedFunc(param:)")) {
                    self.assertReferenced(.varParameter("param"))
                }
            }
        }
    }

    // MARK: - Known Failures

    func testMainActorAnnotation() {
        guard performKnownFailures else { return }

        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass132"))
            assertReferenced(.class("FixtureClass133"))
        }
    }

    // https://bugs.swift.org/browse/SR-14181
    func testSelfReferencedConstructor() {
        guard performKnownFailures else { return }

        analyze(retainPublic: true) {
            assertReferenced(.struct("FixtureStruct3")) {
                self.assertReferenced(.varStatic("instance"))
                self.assertReferenced(.functionConstructor("init(someVar:)"))
            }
        }
    }

    // https://bugs.swift.org/browse/SR-14162
    func testStaticMemberUsedAsSubscriptKey() {
        guard performKnownFailures else { return }

        analyze(retainPublic: true) {
            assertReferenced(.enum("FixtureEnum128")) {
                self.assertReferenced(.varStatic("someVar"))
            }
        }
    }

    // https://bugs.swift.org/browse/SR-13768
    func testCustomConstructorWithLiteral() {
        guard performKnownFailures else { return }

        analyze(retainPublic: true) {
            assertReferenced(.extensionStruct("Array")) {
                self.assertReferenced(.functionConstructor("init(title:)"))
            }
        }
    }

    // Broken as of Xcode 10.
    // https://bugreport.apple.com/web/?problemID=44703843
    func testGetSetPropertyWithDefaultImplementation() {
        guard performKnownFailures else { return }

        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass100")) {
                self.assertReferenced(.varInstance("someGetSetVar"))
            }
            assertReferenced(.protocol("FixtureProtocol100")) {
                self.assertReferenced(.varInstance("someGetSetVar"))
            }
        }
    }
}

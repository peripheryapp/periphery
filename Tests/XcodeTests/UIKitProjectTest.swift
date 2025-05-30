import Configuration
@testable import TestShared

final class UIKitProjectTest: XcodeSourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        let configuration = Configuration()
        configuration.schemes = ["UIKitProject"]

        build(projectPath: UIKitProjectPath, configuration: configuration)
        index(configuration: configuration)
    }

    func testRetainsMainAppEntryPoint() {
        assertReferenced(.class("AppDelegate"))
    }

    func testRetainsSceneDelegateReferencedInInfoPlist() {
        assertReferenced(.class("SceneDelegate"))
    }

    func testRetainsExtensionPrincipalClassReferencedInInfoPlist() {
        assertReferenced(.class("NotificationService"))
    }

    func testRetainsXibReferencedClass() {
        assertReferenced(.class("XibViewController")) {
            self.assertReferenced(.varInstance("button"))
            self.assertReferenced(.varInstance("controllerProperty"))
            self.assertReferenced(.functionMethodInstance("click(_:)"))
        }
        assertReferenced(.class("XibView")) {
            self.assertReferenced(.varInstance("viewProperty"))
        }
    }

    func testRetainsInspectablePropertyInExtension() {
        assertReferenced(.extensionClass("UIView")) {
            self.assertReferenced(.varInstance("customBorderColor"))
        }
    }

    func testRetainsIBActionReferencedViaSubclass() {
        assertReferenced(.class("XibViewController2Base")) {
            self.assertReferenced(.functionMethodInstance("clickFromSubclass(_:)"))
        }
    }

    func testRetainsStoryboardReferencedClass() {
        assertReferenced(.class("StoryboardViewController")) {
            self.assertReferenced(.varInstance("button"))
            self.assertReferenced(.functionMethodInstance("click(_:)"))
        }
    }

    func testRetainsMethodReferencedByObjcSelector() {
        assertReferenced(.class("XibViewController")) {
            self.assertReferenced(.functionMethodInstance("selectorMethod()"))
            self.assertReferenced(.functionMethodInstance("addTargetMethod()"))
        }
    }

    func testMultiTargetFile() {
        assertReferenced(.struct("MultiTargetStruct")) {
            self.assertReferenced(.varStatic("usedInBoth"))
            self.assertReferenced(.varStatic("usedInApp"))
            self.assertReferenced(.varStatic("usedInExt"))
            self.assertNotReferenced(.varStatic("unused"))
        }
    }

    func testRetainsCoreDataValueTransformerSubclass() {
        assertReferenced(.class("EntityValueTransformer")) {
            self.assertReferenced(.functionMethodInstance("transformedValue(_:)"))
            self.assertNotRedundantPublicAccessibility(.functionMethodInstance("transformedValue(_:)"))
        }
        // ValueTransformer subclasses are referenced by generated code that Periphery cannot analyze.
        assertNotRedundantPublicAccessibility(.class("EntityValueTransformer"))
    }

    func testRetainsCoreDataEntityMigrationPolicySubclass() {
        assertReferenced(.class("CustomEntityMigrationPolicy"))
    }

    func testLocalPackageReferences() {
        assertReferenced(.struct("LocalPackageUsedType"))
        assertNotReferenced(.struct("LocalPackageUnusedType"))
    }
}

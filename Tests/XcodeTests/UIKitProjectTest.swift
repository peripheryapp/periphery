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
            // Unused @IB* members should NOT be retained
            self.assertNotReferenced(.varInstance("unusedOutlet"))
            self.assertNotReferenced(.functionMethodInstance("unusedAction(_:)"))
            self.assertNotReferenced(.varInstance("unusedInspectable"))
        }
        assertReferenced(.class("XibView")) {
            self.assertReferenced(.varInstance("viewProperty"))
        }
    }

    func testRetainsXibReferencedClassFromFileSystemFolder() {
        assertReferenced(.class("XibViewController3"))
    }

    func testRetainsInspectablePropertyInExtension() {
        assertReferenced(.extensionClass("UIView")) {
            // Referenced via XIB (used in userDefinedRuntimeAttributes)
            self.assertReferenced(.varInstance("customBorderColor"))
            // Unreferenced - not used in any XIB
            self.assertNotReferenced(.varInstance("unusedExtensionInspectable"))
        }
    }

    func testRetainsIBActionReferencedViaSubclass() {
        assertReferenced(.class("XibViewController2Base")) {
            // Referenced via XIB (connected in XibViewController2Subclass.xib)
            self.assertReferenced(.functionMethodInstance("clickFromSubclass(_:)"))
            // Unreferenced - not connected in XIB
            self.assertNotReferenced(.varInstance("button"))
            self.assertNotReferenced(.varInstance("unusedBaseOutlet"))
            self.assertNotReferenced(.functionMethodInstance("unusedBaseAction(_:)"))
        }
    }

    func testRetainsStoryboardReferencedClass() {
        assertReferenced(.class("StoryboardViewController")) {
            // Referenced via storyboard (connected)
            self.assertReferenced(.varInstance("button"))
            self.assertReferenced(.functionMethodInstance("click(_:)"))
            // Unreferenced - not connected in storyboard
            self.assertNotReferenced(.varInstance("unusedStoryboardOutlet"))
            self.assertNotReferenced(.functionMethodInstance("unusedStoryboardAction(_:)"))
            self.assertNotReferenced(.varInstance("unusedStoryboardInspectable"))
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

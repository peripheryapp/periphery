import XCTest
import Shared
@testable import TestShared
@testable import XcodeSupport
@testable import PeripheryKit

class UIKitProjectTest: SourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        let project = try! XcodeProject.make(path: UIKitProjectPath)

        let driver = XcodeProjectDriver(
            logger: inject(),
            configuration: configuration,
            xcodebuild: inject(),
            project: project,
            schemes: [try! XcodeScheme.make(project: project, name: "UIKitProject")],
            targets: project.targets
        )

        try! driver.build()
        try! driver.index(graph: graph)
        try! Analyzer.perform(graph: graph)
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
}

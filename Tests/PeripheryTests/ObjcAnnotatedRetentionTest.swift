import XCTest
import SystemPackage
@testable import TestShared
@testable import PeripheryKit

#if os(macOS)
final class ObjcAnnotatedRetentionTest: FixtureSourceGraphTestCase {
    static override func setUp() {
        super.setUp()

        configuration.targets = ["ObjcAnnotatedRetentionFixtures"]

        build(driver: SPMProjectDriver.self)
    }

    func testRetainsAnnotatedExtensionDeclarations() {
        analyze(retainObjcAnnotated: true) {
            assertReferenced(.class("FixtureClass214")) {
                self.assertReferenced(.functionMethodInstance("methodInExtension()"))
            }
        }
    }

    func testRetainsExtensionDeclarationsOnObjcMembersAnnotatedClass() {
        analyze(retainObjcAnnotated: true) {
            assertReferenced(.class("FixtureClass217")) {
                self.assertReferenced(.functionMethodInstance("methodInExtension()"))
            }
        }
    }

    func testRetainsObjcProtocolMembers() {
        analyze(retainObjcAnnotated: true) {
            assertReferenced(.protocol("FixtureProtocol215")) {
                self.assertReferenced(.functionMethodInstance("methodInProtocol()"))
            }
        }
    }

    func testRetainsObjcProtocolConformingDeclarations() {
        analyze(retainObjcAnnotated: true) {
            assertReferenced(.protocol("FixtureProtocol216"))
            assertReferenced(.class("FixtureClass216")) {
                self.assertReferenced(.functionMethodInstance("methodInProtocol()"))
            }
        }
    }
}
#endif

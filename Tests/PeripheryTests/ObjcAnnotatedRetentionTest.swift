import SystemPackage
@testable import TestShared
import XCTest

#if os(macOS) // swiftlint:disable:next balanced_xctest_lifecycle
final class ObjcAnnotatedRetentionTest: FixtureSourceGraphTestCase {
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

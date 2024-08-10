import SystemPackage
@testable import TestShared
import XCTest

#if os(macOS) // swiftlint:disable:next balanced_xctest_lifecycle
final class ObjcAccessibleRetentionTest: FixtureSourceGraphTestCase {
    let performKnownFailures = false

    // https://github.com/apple/swift/issues/56327
    func testRetainsOptionalProtocolMethodImplementedInSubclass() {
        guard performKnownFailures else { return }

        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass125Base"))
            assertReferenced(.class("FixtureClass125")) {
                self.assertReferenced(.functionMethodInstance("fileManager(_:shouldRemoveItemAtPath:)"))
            }
        }
    }

    func testRetainsOptionalProtocolMethod() {
        analyze(retainPublic: true) {
            assertReferenced(.class("FixtureClass127")) {
                self.assertReferenced(.functionMethodInstance("someFunc()"))
            }
            assertReferenced(.protocol("FixtureProtocol127")) {
                self.assertReferenced(.functionMethodInstance("optionalFunc()"))
            }
        }
    }

    func testRetainsObjcAnnotatedClass() {
        analyze(retainObjcAccessible: true) {
            assertReferenced(.class("FixtureClass21"))
        }
    }

    func testRetainsImplicitlyObjcAccessibleClass() {
        analyze(retainObjcAccessible: true) {
            assertReferenced(.class("FixtureClass126"))
        }
    }

    func testRetainsObjcAnnotatedMembers() {
        analyze(retainObjcAccessible: true) {
            assertReferenced(.class("FixtureClass22")) {
                self.assertReferenced(.varInstance("someVar"))
                self.assertReferenced(.functionMethodInstance("someMethod()"))
                self.assertReferenced(.functionMethodInstance("somePrivateMethod()"))
            }
        }
    }

    func testDoesNotRetainObjcAnnotatedWithoutOption() {
        analyze {
            assertNotReferenced(.class("FixtureClass23"))
        }
    }

    func testDoesNotRetainMembersOfObjcAnnotatedClass() {
        analyze(retainObjcAccessible: true) {
            assertReferenced(.class("FixtureClass24")) {
                self.assertNotReferenced(.functionMethodInstance("someMethod()"))
                self.assertNotReferenced(.varInstance("someVar"))
            }
        }
    }

    func testObjcMembersAnnotationRetainsMembers() {
        analyze(retainObjcAccessible: true) {
            assertReferenced(.class("FixtureClass25")) {
                self.assertReferenced(.varInstance("someVar"))
                self.assertReferenced(.functionMethodInstance("someMethod()"))
                self.assertNotReferenced(.functionMethodInstance("somePrivateMethod()"))
            }
        }
    }
}
#endif

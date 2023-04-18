import XCTest
import Shared
@testable import TestShared
@testable import PeripheryKit

class RedundantFilePrivateAccessibilityTest: SourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        configuration.targets = ["MainTarget", "TargetA", "TestTarget"]

        build(driver: SPMProjectDriver.self, projectPath: AccessibilityProjectPath)
        index()
    }

	func testRedundantFilePrivateTypes() {
		assertRedundantFilePrivateAccessibility(.class("SubclassThatShouldNotBeFilePrivate"))
		assertRedundantFilePrivateAccessibility(.struct("StructThatShouldNotBeFilePrivate"))
		assertRedundantFilePrivateAccessibility(.enum("EnumThatShouldNotBeFilePrivate"))
		assertRedundantFilePrivateAccessibility(.functionMethodStatic("aFuncThatShouldNotBeFilePrivate()"))
		assertRedundantFilePrivateAccessibility(.varStatic("aVarThatShouldNotBeFilePrivate"))
	}

	func testExtensionRedundantFilePrivateTypes() {
		assertRedundantFilePrivateAccessibility(.class("ExtensionSubclassThatShouldNotBeFilePrivate"))
		assertRedundantFilePrivateAccessibility(.struct("ExtensionStructThatShouldNotBeFilePrivate"))
		assertRedundantFilePrivateAccessibility(.enum("ExtensionEnumThatShouldNotBeFilePrivate"))
		assertRedundantFilePrivateAccessibility(.functionMethodStatic("aExtensionFuncThatShouldNotBeFilePrivate()"))
		assertRedundantFilePrivateAccessibility(.varStatic("aExtensionVarThatShouldNotBeFilePrivate"))
	}


	func testNotRedundantFilePrivateTypes() {
		assertNotRedundantFilePrivateAccessibility(.class("SubclassCorrectlyFilePrivate"))
		assertNotRedundantFilePrivateAccessibility(.struct("StructCorrectlyFilePrivate"))
		assertNotRedundantFilePrivateAccessibility(.enum("EnumCorrectlyFilePrivate"))
		assertNotRedundantFilePrivateAccessibility(.functionMethodStatic("aFuncCorrectlyFilePrivate()"))
		assertNotRedundantFilePrivateAccessibility(.varStatic("aVarCorrectlyFilePrivate"))
	}

	func testExtensionNotRedundantFilePrivateTypes() {
		assertNotRedundantFilePrivateAccessibility(.class("ExtensionSubclassCorrectlyFilePrivate"))
		assertNotRedundantFilePrivateAccessibility(.struct("ExtensionStructCorrectlyFilePrivate"))
		assertNotRedundantFilePrivateAccessibility(.enum("ExtensionEnumCorrectlyFilePrivate"))
		assertNotRedundantFilePrivateAccessibility(.functionMethodStatic("aExtensionFuncCorrectlyFilePrivate()"))
		assertNotRedundantFilePrivateAccessibility(.varStatic("aExtensionVarCorrectlyFilePrivate"))
	}

}


/*



 Periphery currently doesn't support `open` … "Open declarations are not yet implemented"
 So we are looking for cases of:
 - scope of fileprivate when it should be private; it's not used outside of the scope it's defined in
 - scope of internal when it should be private/fileprivate; it's not used outside of the file it's defined in.
	- Maybe OK to not suggest what the scope should be; if we fix to fileprivate then the next pass will warn about needing to be private
 - scope of public when it should be otherwise — This is what the status quo does


 



 */

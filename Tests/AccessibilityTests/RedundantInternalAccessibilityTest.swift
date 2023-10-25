import XCTest
import Shared
@testable import TestShared
@testable import PeripheryKit

class RedundantInternalAccessibilityTest: SourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        configuration.targets = ["MainTarget", "TargetA", "TestTarget"]

        build(driver: SPMProjectDriver.self, projectPath: AccessibilityProjectPath)
        index()
    }

	func testRedundantInternalTypes() {
		assertRedundantInternalAccessibility(.class("RedundantInternalSubclass"))
		assertRedundantInternalAccessibility(.struct("RedundantInternalStruct"))
		assertRedundantInternalAccessibility(.enum("RedundantInternalEnum"))
		assertRedundantInternalAccessibility(.functionMethodStatic("aRedundantInternalFunc()"))
		assertRedundantInternalAccessibility(.varStatic("aRedundantInternalVar"))

		assertRedundantInternalAccessibility(.class("ClassThatCanBePrivate"))
	}

	func testExtensionRedundantInternalTypes() {
		assertRedundantInternalAccessibility(.class("ExtensionRedundantInternalSubclass"))
		assertRedundantInternalAccessibility(.struct("ExtensionRedundantInternalStruct"))
		assertRedundantInternalAccessibility(.enum("ExtensionRedundantInternalEnum"))
		assertRedundantInternalAccessibility(.functionMethodStatic("aExtensionRedundantInternalFunc()"))
		assertRedundantInternalAccessibility(.varStatic("aExtensionRedundantInternalVar"))
	}

	func testNotRedundantInternalTypes() {
		assertNotRedundantInternalAccessibility(.class("NotRedundantInternalSubclass"))
		assertNotRedundantInternalAccessibility(.struct("NotRedundantInternalStruct"))
		assertNotRedundantInternalAccessibility(.enum("NotRedundantInternalEnum"))
		assertNotRedundantInternalAccessibility(.functionMethodStatic("aNotRedundantInternalFunc()"))
		assertNotRedundantInternalAccessibility(.varStatic("aNotRedundantInternalVar"))

		assertNotRedundantInternalAccessibility(.functionMethodStatic("protocolMethod()"))
		assertNotRedundantInternalAccessibility(.functionMethodInstance("applicationDidFinishLaunching(_:)"))

		// Marking entire class as needing to be private so this component shouldn't be flagged
		assertNotRedundantInternalAccessibility(.functionMethodStatic("FunctionThatShouldBePrivateInPrivateClass()"))

	}

	func testExtensionNotRedundantInternalTypes() {
		assertNotRedundantInternalAccessibility(.class("ExtensionNotRedundantInternalSubclass"))
		assertNotRedundantInternalAccessibility(.struct("ExtensionNotRedundantInternalStruct"))
		assertNotRedundantInternalAccessibility(.enum("ExtensionNotRedundantInternalEnum"))
		assertNotRedundantInternalAccessibility(.functionMethodStatic("aExtensionNotRedundantInternalFunc()"))
		assertNotRedundantInternalAccessibility(.varStatic("aExtensionNotRedundantInternalVar"))
	}
}


/*



 Periphery currently doesn't support `open` … "Open declarations are not yet implemented"
 So we are looking for cases of:
 - scope of Internal when it should be private; it's not used outside of the scope it's defined in
 - scope of internal when it should be private/Internal; it's not used outside of the file it's defined in.
	- Maybe OK to not suggest what the scope should be; if we fix to Internal then the next pass will warn about needing to be private
 - scope of public when it should be otherwise — This is what the status quo does


 



 */

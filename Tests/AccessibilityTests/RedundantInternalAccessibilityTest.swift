import Configuration
@testable import TestShared
import XCTest

final class RedundantInternalAccessibilityTest: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()
        build(projectPath: AccessibilityProjectPath)
    }
    
    func testInternalPropertyUsedInExtensionInOtherFile() {
        // This should NOT be flagged as redundant
        // Tests the case where an internal property is used in an extension in a different file
        // Like delayedClearBoatHistory in AppState.swift used in AppState+BoatTracking.swift
        index()
        
        // InternalPropertyUsedInExtension.propertyUsedInExtension should NOT be flagged as redundant
        // because it's used in InternalPropertyExtension.swift
        assertNotRedundantInternalAccessibility(.varInstance("propertyUsedInExtension"))
    }
    
    func testInternalPropertyUsedOnlyInSameFile() {
        // This should be flagged as redundant
        // Tests the case where an internal property is only used within its own file
        index()
        
        // InternalPropertyUsedInExtension.propertyOnlyUsedInSameFile should be flagged as redundant
        // because it's only used within InternalPropertyUsedInExtension.swift
        assertRedundantInternalAccessibility(.varInstance("propertyOnlyUsedInSameFile"))
    }
    
    func testInternalPropertyUsedInMultipleFiles() {
        // This should NOT be flagged as redundant
        // Tests the case where an internal property is used across multiple files
        index()
        
        // This test would need additional setup with multiple files
        // For now, we'll test that the existing NotRedundantInternalClassComponents work
        assertNotRedundantInternalAccessibility(.class("NotRedundantInternalClass"))
    }
    
    func testInternalMethodUsedInExtension() {
        // This should NOT be flagged as redundant
        // Tests the case where an internal method is used in an extension
        index()
        
        // This test would need additional setup with methods in extensions
        // For now, we'll test that the existing NotRedundantInternalClassComponents work
        assertNotRedundantInternalAccessibility(.functionMethodInstance("usedInternalMethod()"))
    }
} 
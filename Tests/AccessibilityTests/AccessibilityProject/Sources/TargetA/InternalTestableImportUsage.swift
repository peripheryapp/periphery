import Foundation

// Should NOT be flagged as redundant - used from test via @testable import
internal class InternalUsedOnlyInTest {
    internal func testOnlyMethod() {}
}

// Should NOT be flagged - used from both test AND production code
internal class InternalUsedInBoth {
    internal func sharedMethod() {}
}

import Foundation

// This file uses InternalUsedInBoth from production code within the same module
// to ensure it's not flagged as redundant internal (since it's used both in production and tests)

struct InternalTestableImportRetainer {
    func retain() {
        _ = InternalUsedInBoth().sharedMethod()
    }
}

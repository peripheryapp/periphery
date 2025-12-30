// Module D: Unused import false-positive for module that provides a conformance
//
// This file imports:
// - UnusedImportFixtureA: provides ConformanceClass and ConformanceProtocol
// - UnusedImportFixtureB: provides ConformanceClass: ConformanceProtocol conformance
// - UnusedImportFixtureC: provides acceptConformingType(_:)
//
// Module B's import is required because it provides the conformance, but no declarations from it
// are directly referenced. Without this import, the call would fail to compile.
//
// The import should NOT be flagged as unused.

import UnusedImportFixtureA  // Module A: type definitions
import UnusedImportFixtureB  // Module B: conformance (no direct references!)
import UnusedImportFixtureC  // Module C: function accepting protocol

// periphery:ignore
public class UnusedImportConformanceTestRetainer {
    public func use() {
        // This call requires ConformanceClass to conform to ConformanceProtocol.
        // - ConformanceClass comes from Module A
        // - acceptConformingType comes from Module C
        // - The conformance is provided by Module B (no symbols directly referenced from B!)
        _ = acceptConformingType(ConformanceClass())
    }
}


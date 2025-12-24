// Module B: Provides conformance for ConformanceClass to ConformanceProtocol
// This module's import should NOT be flagged as unused when the conformance is used

import UnusedImportFixtureA

extension ConformanceClass: ConformanceProtocol {
    public var conformanceProperty: Int { 42 }
}


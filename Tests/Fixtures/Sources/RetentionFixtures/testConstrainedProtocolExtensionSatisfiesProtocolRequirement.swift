import Foundation

// When a protocol extension has a constraint requiring another protocol,
// the extension's members should be recognized as satisfying the constraining protocol's requirements.

public protocol FixtureProtocol1021A {
    var value: String { get }
}

protocol FixtureProtocol1021B {}

// This extension provides a default 'value' for types conforming to both protocols
extension FixtureProtocol1021B where Self: FixtureProtocol1021A {
    var value: String { "default" }
}

public func fixture1021Retainer() {
    // Nested struct - the conformance is satisfied by the constrained extension
    struct Conformer: FixtureProtocol1021A, FixtureProtocol1021B {}
    let instance: FixtureProtocol1021A = Conformer()
    _ = instance.value
}

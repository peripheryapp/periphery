import Foundation

// MARK: - Protocol member with ignore that is NOT superfluous
// The member only has related references from conformances/default implementations,
// not normal references indicating actual usage.

public protocol CorrectlyIgnoredProtocol {
    var ignoredProperty: String { get } // periphery:ignore
}

public extension CorrectlyIgnoredProtocol {
    var ignoredProperty: String { "" }
}

public class CorrectlyIgnoredProtocolConformingClass {
    public let ignoredProperty = 0
}

// MARK: - Protocol member with ignore that IS superfluous
// The member has a normal reference (it's actually called), so the ignore is superfluous.

public protocol SuperfluouslyIgnoredProtocol {
    var superfluousProperty: String { get } // periphery:ignore
}

extension SuperfluouslyIgnoredProtocol {
    var superfluousProperty: String { "" }
}

public class SuperfluouslyIgnoredProtocolConformingClass: SuperfluouslyIgnoredProtocol {
    public var superfluousProperty: String { "" }
}

public func useSuperfluousProtocolMember() {
    let instance: SuperfluouslyIgnoredProtocol = SuperfluouslyIgnoredProtocolConformingClass()
    _ = instance.superfluousProperty
}

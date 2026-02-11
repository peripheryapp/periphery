/*
 ProtocolRequirementAccessibility.swift
 Tests that protocol requirements and conformances are NOT flagged as redundant.
*/

/* Internal protocol with internal requirements. */
internal protocol InternalProtocolWithRequirements {
    func requiredMethod()
    var requiredProperty: Int { get }
}

/* Class conforming to the internal protocol. */
internal class ConformingToInternalProtocol: InternalProtocolWithRequirements {
    /* Should NOT be flagged - this implements a protocol requirement. */
    func requiredMethod() {}

    /* Should NOT be flagged - this implements a protocol requirement. */
    var requiredProperty: Int { 42 }
}

/* Protocol with fileprivate requirement (within same file). */
fileprivate protocol FilePrivateProtocol {
    func filePrivateRequirement()
}

/* Extension conforming to fileprivate protocol. */
extension ConformingToInternalProtocol: FilePrivateProtocol {
    /* Should NOT be flagged - implements protocol requirement. */
    func filePrivateRequirement() {}
}

/* Used by main.swift to ensure these are referenced. */
public class ProtocolRequirementAccessibilityRetainer {
    public init() {}
    public func retain() {
        let obj = ConformingToInternalProtocol()
        obj.requiredMethod()
        _ = obj.requiredProperty
        obj.filePrivateRequirement()
    }
}

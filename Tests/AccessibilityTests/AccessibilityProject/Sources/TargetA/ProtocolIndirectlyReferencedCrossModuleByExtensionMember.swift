public protocol ProtocolIndirectlyReferencedCrossModuleByExtensionMember {}
public extension ProtocolIndirectlyReferencedCrossModuleByExtensionMember {
    func somePublicFunc() {}
}
public class ProtocolIndirectlyReferencedCrossModuleByExtensionMemberImpl: ProtocolIndirectlyReferencedCrossModuleByExtensionMember {
    public init() {}
}

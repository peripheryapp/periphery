public class EmptyExtension {}
extension EmptyExtension {
    func unused() {}
}
extension EmptyExtension {
    // Only comments.
}
public protocol EmptyExtensionProtocol {}
extension EmptyExtension: EmptyExtensionProtocol {}

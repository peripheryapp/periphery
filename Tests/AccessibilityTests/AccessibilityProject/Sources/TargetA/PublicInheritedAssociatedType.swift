import Foundation

public protocol PublicInheritedAssociatedType {}

public protocol PublicInheritedAssociatedTypeProtocol {
    associatedtype Value: PublicInheritedAssociatedType

    var items: [Value] { get }
}

public class PublicInheritedAssociatedTypeClass: PublicInheritedAssociatedTypeProtocol {
    public init() {}
    public let items: [Int] = []
}

extension Int: PublicInheritedAssociatedType {}

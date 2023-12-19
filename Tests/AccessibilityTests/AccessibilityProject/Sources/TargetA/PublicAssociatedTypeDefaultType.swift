import Foundation

public protocol PublicInheritedAssociatedTypeDefaultType {}

public protocol PublicInheritedAssociatedTypeDefaultTypeProtocol {
    associatedtype Value = PublicInheritedAssociatedTypeDefaultType

    var items: [Value] { get }
}

public class PublicInheritedAssociatedTypeDefaultTypeClass: PublicInheritedAssociatedTypeDefaultTypeProtocol {
    public init() {}
    public let items: [Int] = []
}

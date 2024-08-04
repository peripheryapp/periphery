import Foundation

public struct PublicAssociatedValueA {
    public let value: String

}
public struct PublicAssociatedValueB {
    public let value: String
}

public enum PublicEnumWithAssociatedValue {
    case someCase(PublicAssociatedValueA, named: PublicAssociatedValueB)

    public static func getSomeCase() -> Self {
        return .someCase(.init(value: ""), named: .init(value: ""))
    }
}

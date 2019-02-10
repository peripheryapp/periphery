import Foundation

public enum Fixture28Enum_Bare {
    case used
    case unused
}

public enum Fixture28Enum_String: String {
    case used
    case unused
}

public enum Fixture28Enum_Character: Character {
    case used = "1"
    case unused = "2"
}

public enum Fixture28Enum_Int: Int {
    case used
    case unused
}

public enum Fixture28Enum_Float: Float {
    case used
    case unused
}

public enum Fixture28Enum_Double: Double {
    case used
    case unused
}

public enum Fixture28Enum_RawRepresentable: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: String) {
        self = .used
    }

    public var rawValue: String {
        return "op1"
    }

    case used
    case unused
}

public class Fixture28Retainer {
    public var a: Fixture28Enum_Bare = .used
    public var b: Fixture28Enum_String = .used
    public var c: Fixture28Enum_Character = .used
    public var d: Fixture28Enum_Int = .used
    public var e: Fixture28Enum_Float = .used
    public var f: Fixture28Enum_Double = .used
    public var g: Fixture28Enum_RawRepresentable = .used
}

import Foundation

enum Fixture28Enum_Bare {
    case used
    case unused
}

enum Fixture28Enum_String: String {
    case used
    case unused
}

enum Fixture28Enum_Character: Character {
    case used = "1"
    case unused = "2"
}

enum Fixture28Enum_Int: Int {
    case used
    case unused
}

enum Fixture28Enum_Float: Float {
    case used
    case unused
}

enum Fixture28Enum_Double: Double {
    case used
    case unused
}

enum Fixture28Enum_RawRepresentable: RawRepresentable {
    typealias RawValue = String

    init?(rawValue: String) {
        self = .used
    }

    var rawValue: String {
        return "op1"
    }

    case used
    case unused
}

public class Fixture28Retainer {
    public func retainer() {
        let a: Fixture28Enum_Bare = .used
        print(a)
        let b: Fixture28Enum_String = .used
        print(b)
        let c: Fixture28Enum_Character = .used
        print(c)
        let d: Fixture28Enum_Int = .used
        print(d)
        let e: Fixture28Enum_Float = .used
        print(e)
        let f: Fixture28Enum_Double = .used
        print(f)
        let g: Fixture28Enum_RawRepresentable = .used
        print(g)
    }
}

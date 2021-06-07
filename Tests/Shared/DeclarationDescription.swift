import Foundation
import PeripheryKit

struct DeclarationDescription: CustomStringConvertible {
    let kind: Declaration.Kind
    let name: String

    var description: String {
        return "(\(kind.rawValue), \"\(name)\")"
    }

    static func `class`(_ name: String) -> Self {
        self.init(kind: .class, name: name)
    }

    static func `protocol`(_ name: String) -> Self {
        self.init(kind: .protocol, name: name)
    }

    static func `struct`(_ name: String) -> Self {
        self.init(kind: .struct, name: name)
    }

    static func `typealias`(_ name: String) -> Self {
        self.init(kind: .typealias, name: name)
    }

    static func `associatedtype`(_ name: String) -> Self {
        self.init(kind: .associatedtype, name: name)
    }

    static func `enum`(_ name: String) -> Self {
        self.init(kind: .enum, name: name)
    }

    static func enumelement(_ name: String) -> Self {
        self.init(kind: .enumelement, name: name)
    }

    static func functionFree(_ name: String) -> Self {
        self.init(kind: .functionFree, name: name)
    }

    static func functionMethodInstance(_ name: String) -> Self {
        self.init(kind: .functionMethodInstance, name: name)
    }

    static func functionMethodStatic(_ name: String) -> Self {
        self.init(kind: .functionMethodStatic, name: name)
    }

    static func functionMethodClass(_ name: String) -> Self {
        self.init(kind: .functionMethodClass, name: name)
    }

    static func functionOperatorInfix(_ name: String) -> Self {
        self.init(kind: .functionOperatorInfix, name: name)
    }

    static func functionConstructor(_ name: String) -> Self {
        self.init(kind: .functionConstructor, name: name)
    }

    static func functionDestructor(_ name: String) -> Self {
        self.init(kind: .functionDestructor, name: name)
    }

    static func varStatic(_ name: String) -> Self {
        self.init(kind: .varStatic, name: name)
    }

    static func varClass(_ name: String) -> Self {
        self.init(kind: .varClass, name: name)
    }

    static func varInstance(_ name: String) -> Self {
        self.init(kind: .varInstance, name: name)
    }

    static func varParameter(_ name: String) -> Self {
        self.init(kind: .varParameter, name: name)
    }

    static func extensionProtocol(_ name: String) -> Self {
        self.init(kind: .extensionProtocol, name: name)
    }

    static func extensionStruct(_ name: String) -> Self {
        self.init(kind: .extensionStruct, name: name)
    }

    static func extensionClass(_ name: String) -> Self {
        self.init(kind: .extensionClass, name: name)
    }
}

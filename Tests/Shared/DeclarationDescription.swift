import Foundation
@testable import SourceGraph

struct DeclarationDescription: CustomStringConvertible {
    let kind: Declaration.Kind
    let name: String
    let line: Int?

    var description: String {
        var parts = [kind.rawValue, "\"\(name)\""]
        if let line {
            parts.append("line: \(line)")
        }
        return "(\(parts.joined(separator: ", ")))"
    }

    static func `class`(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .class, name: name, line: line)
    }

    static func `protocol`(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .protocol, name: name, line: line)
    }

    static func `struct`(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .struct, name: name, line: line)
    }

    static func `typealias`(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .typealias, name: name, line: line)
    }

    static func `associatedtype`(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .associatedtype, name: name, line: line)
    }

    static func `enum`(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .enum, name: name, line: line)
    }

    static func enumelement(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .enumelement, name: name, line: line)
    }

    static func functionFree(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .functionFree, name: name, line: line)
    }

    static func functionMethodInstance(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .functionMethodInstance, name: name, line: line)
    }

    static func functionMethodStatic(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .functionMethodStatic, name: name, line: line)
    }

    static func functionMethodClass(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .functionMethodClass, name: name, line: line)
    }

    static func functionOperatorInfix(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .functionOperatorInfix, name: name, line: line)
    }

    static func functionConstructor(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .functionConstructor, name: name, line: line)
    }

    static func functionDestructor(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .functionDestructor, name: name, line: line)
    }

    static func functionSubscript(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .functionSubscript, name: name, line: line)
    }

    static func varStatic(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .varStatic, name: name, line: line)
    }

    static func varClass(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .varClass, name: name, line: line)
    }

    static func varInstance(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .varInstance, name: name, line: line)
    }

    static func varParameter(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .varParameter, name: name, line: line)
    }

    static func extensionProtocol(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .extensionProtocol, name: name, line: line)
    }

    static func extensionStruct(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .extensionStruct, name: name, line: line)
    }

    static func extensionClass(_ name: String, line: Int? = nil) -> Self {
        self.init(kind: .extensionClass, name: name, line: line)
    }
}

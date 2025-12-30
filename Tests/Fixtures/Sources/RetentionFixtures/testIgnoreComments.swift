import Foundation
// periphery:ignore
import UnusedModuleFixtures

// periphery:ignore
public class Fixture113 {
    func someFunc(param: String) {
        Fixture114().referencedFunc()
    }
}

public protocol Fixture114Protocol {
    // periphery:ignore:parameters param
    func protocolFunc(param: String)
}

public class Fixture114 {
    func referencedFunc() {}

    // periphery:ignore:parameters b,c
    public func someFunc(a: String, b: String, c: String) {
        print(a)
    }
}

extension Fixture114: Fixture114Protocol {
    // param is ignored because the protocol ignores it.
    public func protocolFunc(param: String) {}
}

public class FixtureClass116 {
    // periphery:ignore
    func someFunc() {}

    // periphery:ignore
    let simpleProperty = 0

    // periphery:ignore
    let (tuplePropertyA, tuplePropertyB) = (0, 0)

    // periphery:ignore
    let multiBindingPropertyA = 0, multiBindingPropertyB = 0

    // periphery:ignore
    var assignOnlyProperty = 0

    // periphery:ignore - some comment describing the need to retain this declaration
    let commentWithTrailingDescription = 0

    public func retain() {
        assignOnlyProperty = 1
    }
}

public class FixtureClass212: Fixture114Protocol {
    // param is ignored because the protocol ignores it.
    public func protocolFunc(param: String) {}
}

public class FixtureClass213: Fixture114 {
    // params a & b are ignored because the base class ignores them.
    public override func someFunc(a: String, b: String, c: String) {}
}

// periphery:ignore
// redundant protocol
public protocol Fixture205Protocol {}
// periphery:ignore
public class Fixture205: Fixture205Protocol {}

// MARK: - Inline comment commands

public class Fixture300Class { // periphery:ignore
}

public class Fixture301Class {} // periphery:ignore

public protocol Fixture302Protocol { // periphery:ignore
}

public protocol Fixture303Protocol {} // periphery:ignore

public struct Fixture304Struct { // periphery:ignore
}

public struct Fixture305Struct {} // periphery:ignore

public protocol Fixture306Protocol {}
public extension Fixture306Protocol { // periphery:ignore
    func foo() {}
}

public enum Fixture307Enum { // periphery:ignore
    case foo
}

public class Fixture308Class {
    var storage: String

    public init() {
        storage = "noValue"
    }

    public init(string: String) { // periphery:ignore
        storage = string
    }

    public func someFunc() { // periphery:ignore
        storage = "someFunc"
    }
}

public class Fixture309Class { // periphery:ignore
    public let reference = Fixture308Class()
}

// Test inline ignore comments on properties
public class Fixture310Class {
    var simplePropertyInlineIgnored: Int = 0 // periphery:ignore
    var computedPropertyInlineIgnored: Int { 0 } // periphery:ignore
    var computedPropertyWithOpenBraceIgnore: Int { // periphery:ignore
        0
    }
}

public protocol Fixture311Protocol {
    var protocolPropertyInlineIgnored: String { get } // periphery:ignore
}

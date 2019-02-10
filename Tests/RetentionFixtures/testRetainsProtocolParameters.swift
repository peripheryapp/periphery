import Foundation

public protocol FixtureProtocol104 {
    // param1 used in single conformance
    func func1(param1: String, param2: String)
    // Unused
    func func2(param: String)
    // Used only in extension
    func func3(param: String)
    // Unused in extension, but used in conformance.
    func func4(param: String)
    // param used in multiple conformances
    static func func5(param: String)
    // Used only in override
    func func6(param: String)
    // Unused, conforming functions are explicitly ignored
    func func7(_ param: String)
}

extension FixtureProtocol104 {
    public func func3(param: String) {
        print(param)
    }

    public func func4(param: String) {}
}

public class FixtureClass104Class1: FixtureProtocol104 {
    public func func1(param1: String, param2: String) {}
    public func func2(param: String) {}

    public static func func5(param: String) {
        print(param)
    }

    public func func6(param: String) {}
    public func func7(_: String) {}
}

public class FixtureClass104Class2: FixtureProtocol104 {
    public func func1(param1: String, param2: String) {
        print(param1)
    }

    public func func2(param: String) {}

    public func func4(param: String) {
        print(param)
    }

    public static func func5(param: String) {
        print(param)
    }

    public func func6(param: String) {}
    public func func7(_: String) {}
}

public class FixtureClass104Class3: FixtureClass104Class2 {
    override public func func6(param: String) {
        print(param)
    }
}

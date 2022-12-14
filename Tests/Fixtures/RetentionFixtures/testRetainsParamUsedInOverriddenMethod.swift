import Foundation

public class FixtureClass101Base {
    // No overrides, unused.
    public func func1(param: String) {}

    // Overridden, used only in base.
    public func func2(param: String) { print(param) }

    // Used in override.
    public func func3(param: String) {}

    // Used in deeply nested override.
    public func func4(param: String) {}

    // Same name with different types, used to validate accuracy.
    public func func4(param: Int) {}

    // Overridden, unused.
    public func func5(param: String) {}

    // Overridden, declared in subclass extension.
    public func func6(param: String) {}

    // Overridden in multiple subclass branches.
    public func func7(param1: String, param2: String) {}
}

public class FixtureClass101Subclass1: FixtureClass101Base {
    public override func func2(param: String) {}

    public override func func3(param: String) {
        print(param)
    }

    public override func func4(param: Int) {}

    public override func func7(param1: String, param2: String) {
        print(param1)
    }
}

public class FixtureClass101Subclass2: FixtureClass101Subclass1 {
    public override func func4(param: String) {
        print(param)
    }

    public override func func4(param: Int) {}

    public override func func5(param: String) {}
    
    public override func func7(param1: String, param2: String) {}
}

public class FixtureClass101Subclass3: FixtureClass101Base {
    public override func func7(param1: String, param2: String) {}
}

public class FixtureClass101InheritForeignBase: NSObject {
    public override func isEqual(_ object: Any?) -> Bool {
        return true
    }
}

public class FixtureClass101InheritForeignSubclass1: FixtureClass101InheritForeignBase {
    public override func isEqual(_ object: Any?) -> Bool {
        return true
    }
}

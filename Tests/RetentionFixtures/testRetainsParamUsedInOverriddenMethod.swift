import Foundation

public class FixtureClass101Base {
    // No overrides, unused.
    public func func1(param: String) {}

    // Overriden, used only in base.
    public func func2(param: String) { print(param) }

    // Used in override.
    public func func3(param: String) {}

    // Used in deeply nested overridd.
    public func func4(param: String) {}

    // Overridden, unused.
    public func func5(param: String) {}
}

public class FixtureClass101Subclass1: FixtureClass101Base {
    public override func func2(param: String) {}

    public override func func3(param: String) {
        print(param)
    }
}

public class FixtureClass101Subclass2: FixtureClass101Subclass1 {
    public override func func4(param: String) {
        print(param)
    }

    public override func func5(param: String) {}
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

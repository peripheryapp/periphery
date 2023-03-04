var fixtureClass117StaticProperty: String?

public class FixtureClass117 {
    var simpleProperty: String?
    var guardedSimpleProperty: String?
    var complexProperty: String? {
        get { nil }
        set { }
    }
    var propertyReferencedFromExtension: String?
    var propertyReferencedFromNestedFunction: String?
    var propertyReferencedFromPropertyAccessor: String?
    var propertyReferencedFromDeepChain: String?

    public var retainedVar: String? {
        get {
            if let propertyReferencedFromPropertyAccessor {
                return propertyReferencedFromPropertyAccessor
            }

            if let privateRetainedVar {
                return privateRetainedVar
            }

            return nil
        }
        set { }
    }

    public var retain: Bool {
        simpleProperty = ""
        propertyReferencedFromDeepChain = ""

        // Nested code block to validate that the references are associated with the topmost code block.
        let _ = [""].map { $0 }

        if let simpleProperty {}
        guard let guardedSimpleProperty else { return false }
        if let complexProperty {}
        if let fixtureClass117StaticProperty {}

        func nested() {
            if let propertyReferencedFromNestedFunction {}
        }

        return true
    }

    private var privateRetainedVar: String? {
        propertyReferencedFromDeepChain
    }
}

extension FixtureClass117 {
    var computedPropertyInExtension: String? {
        nil
    }

    public func retain2() {
        if let propertyReferencedFromExtension {}
        if let computedPropertyInExtension {}
    }
}

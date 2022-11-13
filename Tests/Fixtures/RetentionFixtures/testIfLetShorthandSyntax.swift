var fixtureClass117StaticProperty: String?

public class FixtureClass117 {
    var simpleProperty: String?
    var complexProperty: String? {
        get { nil }
        set { }
    }
    var propertyReferencedFromExtension: String?
    var propertyReferencedFromNestedFunction: String?
    var propertyReferencedFromPropertyAccessor: String?

    public var retainedVar: String? {
        get {
            if let propertyReferencedFromPropertyAccessor {
                return propertyReferencedFromPropertyAccessor
            }

            return nil
        }
        set { }
    }

    public func retain() {
        simpleProperty = ""

        if let simpleProperty {
            _ = simpleProperty
        }

        if let complexProperty {
            _ = complexProperty
        }

        if let fixtureClass117StaticProperty {
            _ = fixtureClass117StaticProperty
        }

        func nested() {
            if let propertyReferencedFromNestedFunction {
                _ = propertyReferencedFromNestedFunction
            }
        }
    }
}

extension FixtureClass117 {
    var computedPropertyInExtension: String? {
        nil
    }

    public func retain2() {
        if let propertyReferencedFromExtension {
            _ = propertyReferencedFromExtension
        }

        if let computedPropertyInExtension {
            _ = computedPropertyInExtension
        }
    }
}

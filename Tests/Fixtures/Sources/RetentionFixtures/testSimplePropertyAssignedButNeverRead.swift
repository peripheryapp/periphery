import Foundation

public class FixtureClass70 {
    static var simpleStaticUnreadVar: String!
    var simpleUnreadVar: String
    var simpleUnreadShadowedVar: String
    var simpleUnreadVarAssignedMultiple: String
    var complexUnreadVar1: String {
        willSet {
            print("complex")
        }
        didSet {
            print("complex")
        }
    }
    var complexUnreadVar2: String {
        get {
            return "complex"
        }
        set {
            print("complex")
        }
    }
    var readVar: String
    // periphery:ignore
    var ignoredSimpleUnreadVar: String

    @Wrapped
    var wrappedProperty: String

    init() {
        simpleUnreadVar = "Hello"
        simpleUnreadShadowedVar = "Hello"
        simpleUnreadVarAssignedMultiple = "1"
        simpleUnreadVarAssignedMultiple = "2"
        complexUnreadVar1 = "Hello"
        readVar = "Hello"
        ignoredSimpleUnreadVar = "Hello"
        wrappedProperty = "Hello"
        FixtureClass70.simpleStaticUnreadVar = "Hello"
    }

    public func someMethod(simpleUnreadShadowedVar: String) {
        self.simpleUnreadShadowedVar = simpleUnreadShadowedVar
        simpleUnreadVar = "World"
        complexUnreadVar1 = "Hello"
        complexUnreadVar2 = "Hello"
        print(readVar)
    }
}

@propertyWrapper
struct Wrapped<Value> {
    var wrappedValue: Value
    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
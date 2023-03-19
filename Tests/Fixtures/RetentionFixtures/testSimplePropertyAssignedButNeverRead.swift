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
    var inferredTypeUnreadVar = someFunc()

    init() {
        simpleUnreadVar = ""
        simpleUnreadShadowedVar = ""
        simpleUnreadVarAssignedMultiple = ""
        simpleUnreadVarAssignedMultiple = ""
        complexUnreadVar1 = ""
        readVar = ""
        ignoredSimpleUnreadVar = ""
        FixtureClass70.simpleStaticUnreadVar = ""
    }

    public func someMethod(simpleUnreadShadowedVar: String) {
        self.simpleUnreadShadowedVar = simpleUnreadShadowedVar
        simpleUnreadVar = ""
        complexUnreadVar1 = ""
        complexUnreadVar2 = ""
        print(readVar)
    }

    private static func someFunc() -> String { "" }
}

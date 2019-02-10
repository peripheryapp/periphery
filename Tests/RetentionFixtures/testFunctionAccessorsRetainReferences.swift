import Foundation

public class FixtureClass63 {
    var referencedByGetter: String?
    var referencedBySetter: String?
    var referencedByDidSet: String?

    public var someVar: String? {
        get {
            return referencedByGetter
        }
        set {
            referencedBySetter = newValue
        }
    }

    public var someOtherVar: String? {
        didSet {
            referencedByDidSet = someOtherVar
        }
    }
}

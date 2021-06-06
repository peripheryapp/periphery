import Foundation

public class FixtureClass36 {
    private var someVar = "test"

    lazy var someLazyVar: String = {
        return someVar
    }()
}

import Foundation

public class FixtureClass106 {
    func myFunc(param: String) {
        fatalError()
    }
}

public class FixtureClass106Subclass: FixtureClass106 {
    required init?(param: String) {
        fatalError("init(coder:) has not been implemented")
    }
}

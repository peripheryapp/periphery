import Foundation

public class FixtureClass102 {
    public func perform() {
        var nestedVar: Bool {
            nested2()
            return true
        }

        func nestedFunc() {
            nested1()
        }

        nestedFunc()
        print(nestedVar)
    }

    func nested1() {}
    func nested2() {}
}

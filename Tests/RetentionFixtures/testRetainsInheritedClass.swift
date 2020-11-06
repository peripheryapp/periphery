import Foundation

class FixtureClass11 {}
class FixtureClass12: FixtureClass11 {}

public class FixtureClass13 {
    var cls: FixtureClass12?

    public func retainer() {
        print(cls ?? "")
    }
}

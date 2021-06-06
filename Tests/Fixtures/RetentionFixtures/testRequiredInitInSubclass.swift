import Foundation

class FixtureClass77Base {
    required init(a: String) {}
    required init(b: String) {}
}

class FixtureClass77: FixtureClass77Base {
    required init(c: String) {
        super.init(a: "a")
    }

    required init(a: String) {
        fatalError("init(a:) has not been implemented")
    }

    required init(b: String) {
        fatalError("init(b:) has not been implemented")
    }
}

public class FixtureClass77Retainer {
    let cls1: FixtureClass77
    let cls2: FixtureClass77Base

    init() {
        cls1 = FixtureClass77(c: "c")
        cls2 = FixtureClass77Base(b: "c")
    }
}

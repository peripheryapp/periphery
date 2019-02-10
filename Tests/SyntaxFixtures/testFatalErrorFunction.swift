import Foundation
import AppKit

public class FixtureClass106: NSView {
    func myFunc(param: String) {
        fatalError()
    }
}

public class FixtureClass106Subclass: FixtureClass106 {
    init() {
        super.init(frame: NSRect.zero)
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

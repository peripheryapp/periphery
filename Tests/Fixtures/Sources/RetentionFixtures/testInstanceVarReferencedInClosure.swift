import Foundation

public class FixtureClass69 {
    private var someVar: String?

    public func someMethod() {
        performClosure { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.someVar = "test"
        }
    }

    private func performClosure(block: () -> Void) {
        block()
    }
}

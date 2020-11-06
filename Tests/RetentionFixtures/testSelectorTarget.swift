import Foundation

public class FixtureClass73 {
    public func someMethod() {
        let s = #selector(someTargetMethod)
        print(s)
    }

    @objc private func someTargetMethod() {}
}

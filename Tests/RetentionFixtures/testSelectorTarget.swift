import Foundation
import AppKit

public class FixtureClass73 {
    private var button: NSButton?

    public func someMethod() {
        button = NSButton(title: "Hi", target: self, action: #selector(someTargetMethod))
    }

    @objc private func someTargetMethod() {
    }
}

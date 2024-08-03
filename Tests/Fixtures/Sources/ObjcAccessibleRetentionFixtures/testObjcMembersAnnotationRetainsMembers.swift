import Foundation

@objcMembers class FixtureClass25: NSObject {
    var someVar: String?
    func someMethod() {}
    private func somePrivateMethod() {} // @objcMembers doesn't apply to private methods.
}

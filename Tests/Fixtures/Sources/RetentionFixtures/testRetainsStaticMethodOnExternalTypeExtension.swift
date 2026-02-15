import Foundation

public class FixtureClassStaticExtMethod {
    public func someMethod() {
        let _ = [Int].emptyArray()
        let _ = [String].constrainedFactory("hello")
        NumberFormatter.customFormat()
    }
}

extension Array {
    static func emptyArray() -> [Any] { [] }
}

extension Array where Element == String {
    static func constrainedFactory(_ value: String) -> [String] { [value] }
}

extension NumberFormatter {
    static func customFormat() {}
}

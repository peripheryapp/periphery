/// Tests that a fileprivate class is NOT flagged as redundant when it's used from a different type in the same file

fileprivate class NotRedundantFilePrivateClass {
    fileprivate static func usedFilePrivateMethod() {}

    static func staticMethodCallingFilePrivate() {
        usedFilePrivateMethod()
    }
}

/// This separate type accesses NotRedundantFilePrivateClass.
/// Since they're in the same file, fileprivate allows the access.
/// If NotRedundantFilePrivateClass were private instead, this would fail to compile.
class NotRedundantFilePrivateClassUser {
    func useFilePrivateClass() {
        NotRedundantFilePrivateClass.staticMethodCallingFilePrivate()
    }
}

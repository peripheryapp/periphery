class UnusedExtension {
    class Inner {}
}
extension UnusedExtension {
    func someFunc() {}
}
extension UnusedExtension.Inner {
    func someFunc() {}
}

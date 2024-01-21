class UnusedNestedTypeWithExtension {
    class Inner {}
}

extension UnusedNestedTypeWithExtension.Inner {
    func unused() {}
}

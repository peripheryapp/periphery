struct FixtureStruct8 {
    dynamic static func originalStaticMethod() {}
    dynamic func originalMethod() {}
    dynamic var originalProperty: Int { 0 }
    dynamic subscript(original index: Int) -> Int { 0}
}

extension FixtureStruct8 {
    @_dynamicReplacement(for: originalMethod)
    func replacementMethod() {}

    @_dynamicReplacement(for: originalProperty)
    var replacementProperty: Int { 0 }

    @_dynamicReplacement(for: subscript(original:))
    subscript(replacement index: Int) -> Int { 0}
}

public struct FixtureStruct8Retainer {
    public func retain() {
        let strct = FixtureStruct8()
        strct.originalMethod()
        _ = strct.originalProperty
        _ = strct[original: 0]
    }
}

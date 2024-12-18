#if canImport(Testing)
import Testing

@Test func swiftTestingFreeFunction() {}

class SwiftTestingClass {
    @Test("displayName") func instanceMethod() {}
    @Test class func classMethod() {}
    @Test static func staticMethod() {}
}

@Suite struct SwiftTestingStructWithSuite {
    @Test func instanceMethod() {}
    @Test("displayName") static func staticMethod() {}
}

@Suite("displayName") class SwiftTestingClassWithSuite {
    @Test func instanceMethod() {}
    @Test("displayName") class func classMethod() {}
    @Test static func staticMethod() {}
}
#endif

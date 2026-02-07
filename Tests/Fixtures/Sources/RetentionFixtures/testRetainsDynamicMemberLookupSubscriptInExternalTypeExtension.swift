import Foundation

// Extension on external @dynamicMemberLookup type (AttributeDynamicLookup)
public extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.FixtureAttributes, T>
    ) -> T {
        self[T.self]
    }
}

public extension AttributeScopes {
    struct FixtureAttributes: AttributeScope {
        let myAttribute: MyFixtureAttribute
    }
}

public enum MyFixtureAttribute: AttributedStringKey {
    public typealias Value = String
    public static let name = "MyFixtureAttribute"
}

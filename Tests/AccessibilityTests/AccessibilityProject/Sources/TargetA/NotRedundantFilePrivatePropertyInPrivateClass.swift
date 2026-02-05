/*
 NotRedundantFilePrivatePropertyInPrivateClass.swift
 Tests that a fileprivate property in a private class is NOT flagged as redundant
 when accessed from a different type (extension) in the same file.

 This replicates the pattern from FilePath+Glob.swift where:
 - A private class has a fileprivate property
 - An extension of a different type accesses that property
 - The fileprivate modifier is necessary for cross-type same-file access
*/

public extension SomePublicType {
    static func accessPrivateClass() -> Set<String> {
        PrivateClassWithFilePrivateProperty().filePrivatePaths
    }
}

private class PrivateClassWithFilePrivateProperty {
    fileprivate var filePrivatePaths: Set<String> = ["path1", "path2"]

    func someMethod() {
        _ = filePrivatePaths.count
    }
}

/*
 This retainer ensures the extension method is used, making the file indexed.
 The key test is that filePrivatePaths is accessed from the SomePublicType extension,
 which is a different type than PrivateClassWithFilePrivateProperty.
*/
public struct SomePublicType {
    public init() {}

    public func retain() {
        _ = SomePublicType.accessPrivateClass()
    }
}

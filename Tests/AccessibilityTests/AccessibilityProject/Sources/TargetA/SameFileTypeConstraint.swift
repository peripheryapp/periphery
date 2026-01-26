// Tests that types used in signatures of other internal types are NOT flagged
// when the containing type must remain internal.

// MARK: - Property Type Constraint

internal enum SameFileConstrainedEnum {
    case one
    case two
}

internal struct SameFileConstrainingStruct {
    let enumValue: SameFileConstrainedEnum
}

// MARK: - Return Type Constraint

internal struct SameFileReturnType {
    var value: Int = 0
}

internal class SameFileClassWithReturnType {
    func getReturnType() -> SameFileReturnType {
        SameFileReturnType(value: 42)
    }
}

// MARK: - Parameter Type Constraint

internal struct SameFileParamType {
    var data: String = ""
}

internal class SameFileClassWithParamType {
    func process(_ param: SameFileParamType) {
        _ = param.data
    }
}

// MARK: - Generic Constraint

internal protocol SameFileConstraintProtocol {
    var id: String { get }
}

internal class SameFileClassWithGenericConstraint {
    func process<T: SameFileConstraintProtocol>(_ item: T) -> String {
        item.id
    }
}

public class SameFileTypeConstraintRetainer {
    public init() {}
    public func use() {
        _ = SameFileConstrainingStruct(enumValue: .one)
        _ = SameFileClassWithReturnType()
        _ = SameFileClassWithParamType()
        _ = SameFileClassWithGenericConstraint()
    }
}

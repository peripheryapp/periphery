import Foundation

public class PublicComparableOperatorFunction: Comparable {}

public func < (lhs: PublicComparableOperatorFunction, rhs: PublicComparableOperatorFunction) -> Bool {
    true
}

public func == (lhs: PublicComparableOperatorFunction, rhs: PublicComparableOperatorFunction) -> Bool {
    true
}

/// Lightweight integer handle representing an interned module name.
/// Used in place of `String` in hot-path `Set`/`Dictionary` operations
/// where string hashing and equality dominate the profile.
public struct ModuleID: Hashable, Comparable, Sendable {
    /// Exclusive upper bound for `rawValue` so that two `ModuleID`s can be
    /// packed into a single `Int` without collisions using base-`packingRadix`.
    @usableFromInline static let packingRadix = 65537

    @usableFromInline let rawValue: Int

    @inlinable
    init(_ rawValue: Int) {
        precondition(rawValue < Self.packingRadix, "ModuleID rawValue exceeds supported packing range")
        self.rawValue = rawValue
    }

    @inlinable
    public static func < (lhs: ModuleID, rhs: ModuleID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

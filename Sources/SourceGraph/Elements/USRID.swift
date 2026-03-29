/// Lightweight integer handle representing an interned USR string.
/// Replaces raw `String` keys in hot-path dictionary operations where
/// string hashing and equality (memcmp) dominate the profile.
public struct USRID: Hashable {
    @usableFromInline let rawValue: Int

    @inlinable
    init(_ rawValue: Int) {
        self.rawValue = rawValue
    }

    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

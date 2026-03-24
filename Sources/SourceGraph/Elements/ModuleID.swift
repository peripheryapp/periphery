/// Lightweight integer handle representing an interned module name.
/// Used in place of `String` in hot-path `Set`/`Dictionary` operations
/// where string hashing and equality dominate the profile.
public struct ModuleID: Hashable, Comparable, Sendable {
    @usableFromInline let rawValue: Int

    @inlinable
    init(_ rawValue: Int) {
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

/// Dynamically-sized bitset over `ModuleID` values. Backed by `[UInt64]`
/// sized to the number of interned modules, replacing `Set<ModuleID>` in
/// hot paths where `formUnion` / `contains` dominated the profile.
struct ModuleBitset {
    var words: [UInt64]
    private var _nonEmpty: Bool = false

    init(wordCount: Int) {
        words = [UInt64](repeating: 0, count: wordCount)
    }

    var isEmpty: Bool { !_nonEmpty }

    mutating func insert(_ id: ModuleID) {
        let (word, bit) = id.rawValue.quotientAndRemainder(dividingBy: 64)
        if word >= words.count {
            words.append(contentsOf: [UInt64](repeating: 0, count: word + 1 - words.count))
        }
        words[word] |= 1 &<< bit
        _nonEmpty = true
    }

    func contains(_ id: ModuleID) -> Bool {
        let (word, bit) = id.rawValue.quotientAndRemainder(dividingBy: 64)
        guard word < words.count else { return false }

        return words[word] & (1 &<< bit) != 0
    }

    mutating func formUnion(_ other: ModuleBitset) {
        if other.words.count > words.count {
            words.append(contentsOf: [UInt64](repeating: 0, count: other.words.count - words.count))
        }
        other.words.withUnsafeBufferPointer { src in
            words.withUnsafeMutableBufferPointer { dst in
                var i = 0
                while i < src.count {
                    dst[i] |= src[i]
                    i &+= 1
                }
            }
        }
        if other._nonEmpty { _nonEmpty = true }
    }
}

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

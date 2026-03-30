import Synchronization

/// Maps USR strings to compact `USRID` integers and back.
/// Thread-safe: uses 16 sharded locks for the string-to-ID direction to reduce
/// contention during concurrent indexing, with an atomic counter for ID
/// allocation and a separate lock for the ID-to-string reverse map.
public final class USRInterner: @unchecked Sendable {
    private static let shardCount = 16
    private static let shardMask = shardCount - 1

    private final class Shard: @unchecked Sendable {
        let dict = Mutex<[String: USRID]>([:])

        func reserveCapacity(_ n: Int) {
            dict.withLock { $0.reserveCapacity(n) }
        }
    }

    private let shards: [Shard]
    private let nextID = Atomic<Int>(0)
    private let reverseMap = Mutex<[String]>([])

    public init() {
        shards = (0..<Self.shardCount).map { _ in Shard() }
    }

    public var count: Int {
        nextID.load(ordering: .relaxed)
    }

    public func intern(_ usr: String) -> USRID {
        let shard = shards[usr.hashValue & Self.shardMask]
        return shard.dict.withLock { dict in
            if let id = dict[usr] { return id }
            let (rawID, _) = nextID.add(1, ordering: .relaxed)
            let id = USRID(rawID)
            dict[usr] = id
            reverseMap.withLock { storage in
                if rawID >= storage.count {
                    storage.append(contentsOf: repeatElement("", count: rawID + 1 - storage.count))
                }
                storage[rawID] = usr
            }
            return id
        }
    }

    public func existing(_ usr: String) -> USRID? {
        let shard = shards[usr.hashValue & Self.shardMask]
        return shard.dict.withLock { $0[usr] }
    }

    public func string(for id: USRID) -> String {
        reverseMap.withLock { $0[id.rawValue] }
    }

    public func reserveCapacity(_ n: Int) {
        let perShard = n / Self.shardCount + 1
        for shard in shards {
            shard.reserveCapacity(perShard)
        }
        reverseMap.withLock { $0.reserveCapacity(n) }
    }
}

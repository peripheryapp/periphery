import Synchronization

/// Maps USR strings to compact `USRID` integers and back.
/// Thread-safe: internal `Mutex` serializes access, allowing concurrent
/// indexer jobs to intern USRs without holding the graph lock.
public final class USRInterner: @unchecked Sendable {
    private struct State {
        var stringToID: [String: USRID] = [:]
        var idToString: [String] = []
    }

    private let state = Mutex(State())

    public init() {}

    public var count: Int {
        state.withLock { $0.idToString.count }
    }

    public func intern(_ usr: String) -> USRID {
        state.withLock { state in
            if let id = state.stringToID[usr] { return id }
            let id = USRID(state.idToString.count)
            state.stringToID[usr] = id
            state.idToString.append(usr)
            return id
        }
    }

    public func existing(_ usr: String) -> USRID? {
        state.withLock { $0.stringToID[usr] }
    }

    public func string(for id: USRID) -> String {
        state.withLock { $0.idToString[id.rawValue] }
    }

    public func reserveCapacity(_ n: Int) {
        state.withLock { state in
            state.stringToID.reserveCapacity(n)
            state.idToString.reserveCapacity(n)
        }
    }
}

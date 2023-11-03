import Foundation

public final class Benchmark {
    @inlinable
    public static func measure(block: () throws -> Void) rethrows -> String {
        let start = Date()
        try block()
        let end = Date()
        let elapsed = end.timeIntervalSince(start)
        return String(format: "%.03f", elapsed)
    }
}

import Foundation

// periphery:ignore
public class IgnoreCommentCommand {}
public class IgnoreCommentCommandRetainer {
    public init() {}
    public func retain() {
        _ = IgnoreCommentCommand()
    }
}

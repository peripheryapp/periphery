// periphery:ignore:all

import Foundation

public class IgnoreAllCommentCommand {}
public class IgnoreAllCommentCommandRetainer {
    public init() {}
    public func retain() {
        _ = IgnoreAllCommentCommand()
    }
}
import Foundation

public struct ImportStatement {
    public let module: String
    public let isTestable: Bool
    public let isExported: Bool
    public let location: Location
    public let commentCommands: [CommentCommand]

    public init(
        module: String,
        isTestable: Bool,
        isExported: Bool,
        location: Location,
        commentCommands: [CommentCommand]
    ) {
        self.module = module
        self.isTestable = isTestable
        self.isExported = isExported
        self.location = location
        self.commentCommands = commentCommands
    }
}

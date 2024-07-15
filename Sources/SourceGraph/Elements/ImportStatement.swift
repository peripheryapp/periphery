import Foundation

public struct ImportStatement {
    public let module: String
    public let isTestable: Bool
    public let isExported: Bool
    public let location: Location

    public init(
        module: String,
        isTestable: Bool,
        isExported: Bool,
        location: Location
    ) {
        self.module = module
        self.isTestable = isTestable
        self.isExported = isExported
        self.location = location
    }
}

import Foundation

public struct ImageAssetReference: Hashable {
    public enum Source {
        case swift
        case interfaceBuilder
    }

    public init(name: String, location: Location, source: Source) {
        self.name = name
        self.location = location
        self.source = source
    }

    public let name: String
    public let location: Location
    public let source: Source
}

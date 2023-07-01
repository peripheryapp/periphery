import Foundation

public struct IndexTarget: Hashable {
    public let name: String
    public var triple: String?

    public init(name: String, triple: String? = nil) {
        self.name = name
        self.triple = triple
    }
}

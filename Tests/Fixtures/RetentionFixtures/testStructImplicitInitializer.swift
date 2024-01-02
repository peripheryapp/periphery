import Foundation

public struct FixtureStruct13_Codable: Codable {
    let assignOnly: Int
}

public struct FixtureStruct13_NotCodable {
    let assignOnly: Int
    let used: Int
}

public struct FixtureStruct13Retainer {
    public func retain() throws {
        let data = "".data(using: .utf8)!
        _ = try JSONDecoder().decode(FixtureStruct13_Codable.self, from: data)
        _ = FixtureStruct13_NotCodable(assignOnly: 0, used: 0).used
    }
}

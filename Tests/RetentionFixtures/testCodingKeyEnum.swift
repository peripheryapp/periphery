import Foundation

public protocol FixtureClass74Codable: Codable {}
public protocol FixtureClass74CodingKey: CodingKey {}

public class FixtureClass74: FixtureClass74Codable {
    var someVar: String?

    enum CodingKeys: FixtureClass74CodingKey {
        case someVar
    }
}

public class FixtureClass75: Decodable {
    var someVar: String?

    enum CodingKeys: CodingKey {
        case someVar
    }
}

public class FixtureClass76 { // Doesn't conform to Codable, so the enum is unused.
    enum CodingKeys: CodingKey {
        case someVar
    }
}

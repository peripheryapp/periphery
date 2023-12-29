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

public class FixtureClass203: Encodable {
    var someVar: String?

    enum CodingKeys: CodingKey {
        case someVar
    }
}

public class FixtureClass111: Codable { // Codable is a typealias, so it has different behaviour.
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

public struct FixtureClass120 {
  let someVar: String

  enum CodingKeys: CodingKey {
      case someVar
  }
}

extension FixtureClass120: Decodable {}

// CustomStringConvertible doesn't actually inherit Codable, we're just using it because we don't have an external
// module in which to declare our own type.
public struct FixtureClass218: CustomStringConvertible {
    public var description: String = ""

    let someVar: String

    enum CodingKeys: CodingKey {
        case someVar
    }
}

public class FixtureClass220: Encodable {
    public var someUsedVar: String?
    var someUnusedVar: String?

    enum CodingKeys: CodingKey {
        case someUsedVar
        case someUnusedVar
    }
}

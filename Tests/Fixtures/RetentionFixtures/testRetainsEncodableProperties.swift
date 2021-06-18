import Foundation

public class FixtureClass204: Codable {
    var someVar: String
}

public class FixtureClass205: Encodable {
    var someVar: String = ""
}

public protocol FixtureProtocol206: Codable {}

public class FixtureClass206: FixtureProtocol206 {
    var someVar: String
}

public protocol FixtureProtocol207: Encodable {}

public class FixtureClass207: FixtureProtocol207 {
    var someVar: String = ""
}

public protocol FixtureProtocol208Base: Encodable {}
public protocol FixtureProtocol208: FixtureProtocol208Base {}

public class FixtureClass208: FixtureProtocol208 {
    var someVar: String = ""
}

// CustomStringConvertible doesn't actually inherit Encodable, we're just using it because we don't have an external
// module in which to declare our own type.
public class FixtureClass209: CustomStringConvertible {
    var someVar: String = ""
    public var description: String { "" }
}

public class FixtureClass210 {
    var someVar: String = ""
}
extension FixtureClass210: Encodable {}

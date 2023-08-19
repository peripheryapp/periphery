public class UnusedCodableProperty: Codable {
    public var used: String?
    var unused: String?

    enum CodingKeys: CodingKey {
        case used
        case unused
    }
}

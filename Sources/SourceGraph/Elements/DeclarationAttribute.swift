public struct DeclarationAttribute: Hashable, CustomStringConvertible {
    let name: String
    private let arguments: String?

    public init(name: String, arguments: String?) {
        self.name = name
        self.arguments = arguments
    }

    public var description: String {
        if let arguments {
            "\(name)(\(arguments))"
        } else {
            name
        }
    }
}

extension DeclarationAttribute: Comparable {
    public static func < (lhs: DeclarationAttribute, rhs: DeclarationAttribute) -> Bool {
        lhs.name < rhs.name
    }
}

public enum ProjectFileKind {
    case interfaceBuilder
    case infoPlist
    case xcDataModel
    case xcMappingModel

    public var extensions: [String] {
        switch self {
        case .interfaceBuilder:
            ["xib", "storyboard"]
        case .infoPlist:
            ["plist"]
        case .xcDataModel:
            ["xcdatamodeld"]
        case .xcMappingModel:
            ["xcmappingmodel"]
        }
    }
}

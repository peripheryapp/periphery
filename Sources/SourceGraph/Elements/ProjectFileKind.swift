public enum ProjectFileKind {
    case interfaceBuilder
    case infoPlist
    case xcDataModel
    case xcMappingModel

    public var extensions: [String] {
        switch self {
        case .interfaceBuilder:
            return ["xib", "storyboard"]
        case .infoPlist:
            return ["plist"]
        case .xcDataModel:
            return ["xcdatamodeld"]
        case .xcMappingModel:
            return ["xcmappingmodel"]
        }
    }
}

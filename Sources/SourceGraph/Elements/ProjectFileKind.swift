public enum ProjectFileKind: CaseIterable {
    case assetCatalog
    case interfaceBuilder
    case infoPlist
    case xcDataModel
    case xcMappingModel

    public var extensions: [String] {
        switch self {
        case .assetCatalog:
            ["xcassets"]
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

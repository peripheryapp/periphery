import Foundation
import SystemPackage

struct AssetReference: Hashable {
    enum Source {
        case interfaceBuilder
        case infoPlist
        case xcDataModel
    }

    init(absoluteName: String, source: Source) {
        if let name = absoluteName.split(separator: ".").last {
            self.name = String(name)
        } else {
            self.name = absoluteName
        }
        self.source = source
    }

    let name: String
    let source: Source
}

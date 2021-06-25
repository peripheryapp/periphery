import Foundation
import SystemPackage

struct AssetReference: Hashable {
    init(absoluteName: String, source: ProjectFileKind) {
        if let name = absoluteName.split(separator: ".").last {
            self.name = String(name)
        } else {
            self.name = absoluteName
        }
        self.source = source
    }

    let name: String
    let source: ProjectFileKind
}

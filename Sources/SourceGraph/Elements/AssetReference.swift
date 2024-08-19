import Foundation
import SystemPackage

public struct AssetReference: Hashable {
    public init(absoluteName: String, source: ProjectFileKind) {
        if let name = absoluteName.split(separator: ".").last {
            self.name = String(name)
        } else {
            name = absoluteName
        }
        self.source = source
    }

    public let name: String
    public let source: ProjectFileKind
}

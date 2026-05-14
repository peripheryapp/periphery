import Foundation
import SourceGraph
import SystemPackage

final class AssetCatalogParser {
    private let path: FilePath

    required init(path: FilePath) {
        self.path = path
    }

    func parse() -> Set<Declaration> {
        guard let enumerator = FileManager.default.enumerator(
            at: path.url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var declarations = Set<Declaration>()

        for case let url as URL in enumerator {
            guard url.pathExtension == "imageset" else { continue }

            let imageSetPath = FilePath(url.path)
            let name = url.deletingPathExtension().lastPathComponent
            let contentsPath = imageSetPath.appending("Contents.json")
            let locationPath = FileManager.default.fileExists(atPath: contentsPath.lexicallyNormalized().string) ? contentsPath : imageSetPath
            let locationFile = SourceFile(path: locationPath, modules: [])
            let location = Location(file: locationFile, line: 1, column: 1)
            let usr = "image-asset-\(imageSetPath.lexicallyNormalized().string)"

            declarations.insert(
                Declaration(
                    name: name,
                    kind: .imageAsset,
                    usrs: [usr],
                    location: location
                )
            )
        }

        return declarations
    }
}

import Foundation
import AEXML
import SystemPackage

final class XCMappingModelParser {
    private let path: FilePath

    required init(path: FilePath) {
        self.path = path.appending("xcmapping.xml")
    }

    func parse() throws -> [AssetReference] {
        guard let data = FileManager.default.contents(atPath: path.string) else { return [] }
        let structure = try AEXMLDocument(xml: data)
        return references(from: structure.root).map {
            AssetReference(absoluteName: $0, source: .xcMappingModel)
        }
    }

    // MARK: - Private

    private func references(from element: AEXMLElement) -> [String] {
        var names: [String] = []

        for child in element.children {
            if child.attributes["name"] == "migrationpolicyclassname" {
                names.append(child.string)
            }

            names += references(from: child)
        }

        return names
    }
}

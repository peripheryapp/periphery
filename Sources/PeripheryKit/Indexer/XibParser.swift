import Foundation
import AEXML
import SystemPackage

final class XibParser {
    private let path: FilePath

    required init(path: FilePath) {
        self.path = path
    }

    func parse() throws -> [AssetReference] {
        guard let data = FileManager.default.contents(atPath: path.string) else { return [] }
        let structure = try AEXMLDocument(xml: data)
        return references(from: structure.root).map {
            AssetReference(absoluteName: $0, source: .interfaceBuilder)
        }
    }

    // MARK: - Private

    private func references(from element: AEXMLElement) -> [String] {
        var names: [String] = []

        for child in element.children {
            if let name = child.attributes["customClass"] {
                names.append(name)
            }

            names += references(from: child)
        }

        return names
    }
}

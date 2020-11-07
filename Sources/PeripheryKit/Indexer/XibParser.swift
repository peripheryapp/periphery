import Foundation
import AEXML
import PathKit

struct XibReference {
    let xibPath: Path
    let className: String
}

final class XibParser {
    private let path: Path

    required init(path: Path) {
        self.path = path
    }

    func parse() throws -> [XibReference] {
        guard let data = FileManager.default.contents(atPath: path.string) else { return [] }

        let structure = try AEXMLDocument(xml: data)
        let elements = filter(structure.root)
        return elements.compactMap {
            guard let customClass = $0.attributes["customClass"] else { return nil }
            return XibReference(xibPath: path, className: customClass)
        }
    }

    // MARK: - Private

    private func filter(_ element: AEXMLElement) -> [AEXMLElement] {
        var elements: [AEXMLElement] = []

        for child in element.children {
            if child.attributes["customClass"] != nil {
                elements.append(child)
            }

            elements += filter(child)
        }

        return elements
    }
}

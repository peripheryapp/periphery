import Foundation
import SWXMLHash
import PathKit

struct XibReference {
    let xibPath: Path
    let className: String
    let moduleName: String?
}

class XibParser {
    private let path: Path

    required init(path: Path) {
        self.path = path
    }

    func parse() -> [XibReference] {
        guard let data = FileManager.default.contents(atPath: path.string),
            let xml = String(data: data, encoding: .utf8) else { return [] }

        let config = SWXMLHash.config { config in
            config.caseInsensitive = false
            config.shouldProcessLazily = true
        }

        let structure = config.parse(xml)
        let elements = filter(structure)
        return elements.compactMap {
            guard let customClass = $0.attribute(by: "customClass")?.text else { return nil }
            let customModule = $0.attribute(by: "customModule")?.text
            return XibReference(xibPath: path,
                                className: customClass,
                                moduleName: customModule)
        }
    }

    // MARK: - Private

    private func filter(_ indexer: XMLIndexer) -> [SWXMLHashXMLElement] {
        var elements: [SWXMLHashXMLElement] = []

        for child in indexer.children {
            if let element = child.element, element.attribute(by: "customClass") != nil {
                elements.append(element)
            }

            elements += filter(child)
        }

        return elements
    }
}

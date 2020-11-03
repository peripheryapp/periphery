import Foundation
import SWXMLHash
import PathKit

struct InfoPlistReference {
    let infoPlistPath: Path
    let className: String
}

final class InfoPlistParser {
    private static let elements = ["UISceneClassName", "UISceneDelegateClassName"]
    private let path: Path

    required init(path: Path) {
        self.path = path
    }

    func parse() -> [InfoPlistReference] {
        guard let data = FileManager.default.contents(atPath: path.string),
              let xml = String(data: data, encoding: .utf8) else { return [] }

        let config = SWXMLHash.config { config in
            config.caseInsensitive = false
            config.shouldProcessLazily = true
        }

        let structure = config.parse(xml)
        let elements = filter(structure)

        return elements.compactMap {
            guard let className = $0.innerXML.split(separator: ".").last else { return nil }
            return InfoPlistReference(infoPlistPath: path, className: String(className))
        }
    }

    // MARK: - Private

    private func filter(_ indexer: XMLIndexer) -> [SWXMLHashXMLElement] {
        var elements: [SWXMLHashXMLElement] = []

        for (i, child) in indexer.children.enumerated() {
            if child.element?.name == "key",
               let element = child.element?.innerXML,
               Self.elements.contains(element) {
                if let element = indexer.children[safe: i + 1]?.element {
                    elements.append(element)
                }
            }

            elements += filter(child)
        }

        return elements
    }
}

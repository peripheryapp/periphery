import Foundation
import AEXML
import PathKit

struct InfoPlistReference {
    let infoPlistPath: Path
    let className: String
}

final class InfoPlistParser {
    private static let elements = ["UISceneClassName", "UISceneDelegateClassName", "NSExtensionPrincipalClass"]
    private let path: Path

    required init(path: Path) {
        self.path = path
    }

    func parse() throws -> [InfoPlistReference] {
        guard let data = FileManager.default.contents(atPath: path.string) else { return [] }

        let structure = try AEXMLDocument(xml: data)
        let elements = filter(structure.root)

        return elements.compactMap {
            guard let className = $0.string.split(separator: ".").last else { return nil }
            return InfoPlistReference(infoPlistPath: path, className: String(className))
        }
    }

    // MARK: - Private

    private func filter(_ parent: AEXMLElement) -> [AEXMLElement] {
        var elements: [AEXMLElement] = []

        for (i, child) in parent.children.enumerated() {
            if child.name == "key", Self.elements.contains(child.string) {
                if let nextElement = parent.children[safe: i + 1] {
                    elements.append(nextElement)
                }
            }

            elements += filter(child)
        }

        return elements
    }
}

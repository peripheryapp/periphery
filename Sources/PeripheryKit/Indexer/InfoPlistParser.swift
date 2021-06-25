import Foundation
import SystemPackage
import AEXML

final class InfoPlistParser {
    private static let elements = ["UISceneClassName", "UISceneDelegateClassName", "NSExtensionPrincipalClass"]
    private let path: FilePath

    required init(path: FilePath) {
        self.path = path
    }

    func parse() throws -> [AssetReference] {
        guard let data = FileManager.default.contents(atPath: path.string) else { return [] }

        let structure = try AEXMLDocument(xml: data)
        let elements = filter(structure.root)

        return elements.map {
            AssetReference(absoluteName: $0.string, source: .infoPlist)
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

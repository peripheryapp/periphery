import AEXML
import Foundation
import SourceGraph
import SystemPackage

final class XibParser: NSObject, XMLParserDelegate {
    private var customClassNames: [String] = []
    private var currentElementAttributes: [String: String] = [:]

    private let path: FilePath

    required init(path: FilePath) {
        self.path = path
    }

    func parse() -> [AssetReference] {
        guard let data = FileManager.default.contents(atPath: path.string) else { return [] }
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return customClassNames.map { AssetReference(absoluteName: $0, source: .interfaceBuilder) }
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        currentElementAttributes = attributeDict
        if let customClass = attributeDict["customClass"] {
            customClassNames.append(customClass)
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentElementAttributes = [:]
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Parse error: \(parseError.localizedDescription)")
    }
}

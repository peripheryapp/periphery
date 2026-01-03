import Foundation
import SystemPackage

final class XCStringsParser {
    private let path: FilePath

    required init(path: FilePath) {
        self.path = path
    }

    func parse() throws -> Set<String> {
        guard let data = FileManager.default.contents(atPath: path.string) else { return [] }

        let catalog = try JSONDecoder().decode(XCStringsCatalog.self, from: data)
        return Set(catalog.strings.keys)
    }
}

// MARK: - JSON Structure

private struct XCStringsCatalog: Decodable {
    let strings: [String: XCStringsEntry]

    private enum CodingKeys: String, CodingKey {
        case strings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        strings = try container.decodeIfPresent([String: XCStringsEntry].self, forKey: .strings) ?? [:]
    }
}

private struct XCStringsEntry: Decodable {
    // We only need to know the key exists, not the actual localizations
}

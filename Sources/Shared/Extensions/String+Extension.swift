import Foundation

public extension String {
    var trimmed: String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    func escapedForXML() -> String {
        // & needs to go first, otherwise other replacements will be replaced again
        let htmlEscapes = [
            ("&", "&amp;"),
            ("\"", "&quot;"),
            ("'", "&apos;"),
            (">", "&gt;"),
            ("<", "&lt;")
        ]
        var newString = self
        for (key, value) in htmlEscapes {
            newString = newString.replacingOccurrences(of: key, with: value)
        }
        return newString
    }

    // http://www.cse.yorku.ca/~oz/hash.html
    var djb2: Int {
        unicodeScalars
            .map { $0.value }
            .reduce(5381) { ($0 << 5) &+ $0 &+ Int($1) }
    }

    var djb2Hex: String {
        String(format: "%02x", djb2)
    }
}

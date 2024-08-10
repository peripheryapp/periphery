import Foundation

public extension String {
    @inlinable var trimmed: String {
        trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    @inlinable
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
    @inlinable var djb2: Int {
        unicodeScalars
            .map { $0.value }
            .reduce(5_381) { ($0 << 5) &+ $0 &+ Int($1) }
    }

    @inlinable var djb2Hex: String {
        String(format: "%02x", djb2)
    }
}

import Foundation
import CryptoKit

public extension String {
    var trimmed: String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    var sha1: String {
        guard let data = data(using: .utf8) else {
            fatalError("Failed to get data for string '\(self)'")
        }
        return Insecure.SHA1.hash(data: data).hexStr
    }
}

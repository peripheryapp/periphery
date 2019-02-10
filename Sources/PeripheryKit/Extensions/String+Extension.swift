import Foundation

public extension String {
    var trimmed: String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    func counted(_ count: Int) -> String {
        var word = self + "s"

        if count == 1 {
            word = self
        }

        return "\(count) \(word)"
    }
}

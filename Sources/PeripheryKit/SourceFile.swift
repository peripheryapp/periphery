import Foundation
import PathKit

public struct SourceFile {
    let path: Path

    init(path: Path) {
        self.path = path
    }
}

extension SourceFile: Hashable {
    public var hashValue: Int {
        return path.hashValue
    }
}

extension SourceFile: Equatable {
    public static func == (lhs: SourceFile, rhs: SourceFile) -> Bool {
        return lhs.path == rhs.path
    }
}

extension SourceFile: CustomStringConvertible {
    public var description: String {
        return "File(\(path))"
    }
}

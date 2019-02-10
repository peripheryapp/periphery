import Foundation
import PathKit

public protocol XcodeProjectlike {
    var path: Path { get }
    var targets: Set<Target> { get } // Set to ensure uniqueness
    var type: String { get }
    var name: String { get }
    var sourceRoot: Path { get }

    func schemes() throws -> Set<Scheme> // Set to ensure uniqueness
}

public extension XcodeProjectlike {
    var name: String {
        return path.lastComponentWithoutExtension
    }
}

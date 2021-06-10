import Foundation
import SystemPackage
import PeripheryKit

protocol XcodeProjectlike: AnyObject {
    var path: FilePath { get }
    var targets: Set<XcodeTarget> { get } // Set to ensure uniqueness
    var type: String { get }
    var name: String { get }
    var sourceRoot: FilePath { get }

    func schemes() throws -> Set<XcodeScheme> // Set to ensure uniqueness
}

extension XcodeProjectlike {
    var name: String {
        return path.lastComponent?.stem ?? ""
    }
}

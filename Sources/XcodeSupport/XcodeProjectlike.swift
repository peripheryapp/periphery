import Foundation
import SystemPackage

protocol XcodeProjectlike: AnyObject {
    var path: FilePath { get }
    var targets: Set<XcodeTarget> { get }
    var type: String { get }
    var name: String { get }
    var sourceRoot: FilePath { get }

    func schemes(additionalArguments: [String]) throws -> Set<String>
}

extension XcodeProjectlike {
    var name: String {
        path.lastComponent?.stem ?? ""
    }
}

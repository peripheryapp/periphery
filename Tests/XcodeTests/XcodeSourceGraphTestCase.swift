import Foundation
import Shared
import ProjetDrivers
import SystemPackage
@testable import TestShared

class XcodeSourceGraphTestCase: SourceGraphTestCase {
    static func build(projectPath: FilePath) {
        projectPath.chdir {
            let driver = try! XcodeProjectDriver.build(projectPath: projectPath)
            try! driver.build()
            plan = try! driver.plan(logger: Logger().contextualized(with: "index"))
        }
    }
}

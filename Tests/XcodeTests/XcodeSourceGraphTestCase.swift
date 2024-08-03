import Foundation
import Shared
import SystemPackage
@testable import TestShared
import XcodeSupport

class XcodeSourceGraphTestCase: SourceGraphTestCase {
    static func build(projectPath: FilePath) {
        projectPath.chdir {
            let driver = try! XcodeProjectDriver.build(projectPath: projectPath)
            try! driver.build()
            plan = try! driver.plan(logger: Logger().contextualized(with: "index"))
        }
    }
}

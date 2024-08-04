import Foundation
import SystemPackage
import PeripheryKit
import Shared

class SPMSourceGraphTestCase: SourceGraphTestCase {
    static func build(projectPath: FilePath = ProjectRootPath) {
        projectPath.chdir {
            let driver = try! SPMProjectDriver.build()
            try! driver.build()
            plan = try! driver.plan(logger: Logger().contextualized(with: "index"))
        }
    }
}

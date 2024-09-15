import Foundation
import ProjectDrivers
import Shared
import SystemPackage

class SPMSourceGraphTestCase: SourceGraphTestCase {
    static func build(projectPath: FilePath = ProjectRootPath) {
        projectPath.chdir {
            let driver = try! SPMProjectDriver(configuration: configuration, shell: shell, logger: logger)
            try! driver.build()
            plan = try! driver.plan(logger: logger.contextualized(with: "index"))
        }
    }
}

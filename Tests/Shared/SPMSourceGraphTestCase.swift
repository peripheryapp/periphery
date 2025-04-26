import Configuration
import Foundation
import ProjectDrivers
import SystemPackage

class SPMSourceGraphTestCase: SourceGraphTestCase {
    static func build(projectPath: FilePath = ProjectRootPath, configuration: Configuration = .init()) {
        projectPath.chdir {
            let driver = try! SPMProjectDriver(configuration: configuration, shell: shell, logger: logger)
            try! driver.build()
            plan = try! driver.plan(logger: logger.contextualized(with: "index"))
        }
    }
}

import Configuration
import Foundation
import ProjectDrivers
import SystemPackage
@testable import TestShared

class XcodeSourceGraphTestCase: SourceGraphTestCase {
    static func build(projectPath: FilePath, configuration: Configuration) {
        projectPath.chdir {
            let driver = try! XcodeProjectDriver(
                projectPath: projectPath,
                configuration: configuration,
                shell: shell,
                logger: logger
            )
            try! driver.build()
            plan = try! driver.plan(logger: logger.contextualized(with: "index"))
        }
    }
}

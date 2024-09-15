import Foundation
import ProjectDrivers
import Shared
import SystemPackage
@testable import TestShared

class XcodeSourceGraphTestCase: SourceGraphTestCase {
    static func build(projectPath: FilePath) {
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

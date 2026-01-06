import Foundation
import Logger
import ProjectDrivers
import Shared
import SystemPackage

final class SPMProjectSetupGuide: SetupGuideHelpers, SetupGuide {
    static func detect(logger: Logger) -> Self? {
        guard SPM.isSupported else { return nil }

        return Self(logger: logger)
    }

    var projectKindName: String {
        "Swift Package"
    }

    func perform() throws -> ProjectKind {
        .spm
    }

    var commandLineOptions: [String] {
        []
    }
}

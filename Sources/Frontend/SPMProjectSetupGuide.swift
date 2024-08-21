import Foundation
import Shared
import SystemPackage
import ProjectDrivers

final class SPMProjectSetupGuide: SetupGuideHelpers, SetupGuide {
    static func detect() -> Self? {
        guard SPM.isSupported else { return nil }
        return Self()
    }

    var projectKindName: String {
        "Swift Project Manager"
    }

    func perform() throws -> ProjectKind {
        .spm
    }

    var commandLineOptions: [String] {
        []
    }
}

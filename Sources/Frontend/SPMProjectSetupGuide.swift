import Foundation
import ProjectDrivers
import Shared
import SystemPackage

final class SPMProjectSetupGuide: SetupGuideHelpers, SetupGuide {
    static func detect() -> Self? {
        guard SPM.isSupported else { return nil }
        return Self()
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

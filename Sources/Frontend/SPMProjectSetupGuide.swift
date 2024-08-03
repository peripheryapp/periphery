import Foundation
import SystemPackage
import PeripheryKit
import Shared

final class SPMProjectSetupGuide: SetupGuideHelpers, ProjectSetupGuide {
    var projectKind: ProjectKind {
        .spm
    }

    var isSupported: Bool {
        SPM.isSupported
    }

    func perform() {}

    var commandLineOptions: [String] {
        []
    }
}

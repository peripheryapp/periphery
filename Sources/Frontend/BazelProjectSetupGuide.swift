import Foundation
import Logger
import ProjectDrivers
import Shared
import SystemPackage

final class BazelProjectSetupGuide: SetupGuideHelpers, SetupGuide {
    static func detect() -> Self? {
        guard BazelProjectDriver.isSupported else { return nil }
        return Self()
    }

    var projectKindName: String {
        "Bazel"
    }

    func perform() throws -> ProjectKind {
        print(logger.colorize("\nAdd the following snippet to your MODULE.bazel file:", .bold))
        print(logger.colorize("""
        bazel_dep(name = "periphery", version = "\(PeripheryVersion)")
        use_repo(use_extension("@periphery//bazel:generated.bzl", "generated"), "periphery_generated")
        """, .lightGray))
        print(logger.colorize("\nEnter to continue when ready ", .bold), terminator: "")
        _ = readLine()

        return .bazel
    }

    var commandLineOptions: [String] {
        ["--bazel"]
    }
}

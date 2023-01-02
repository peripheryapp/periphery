import Foundation
import SystemPackage
import PeripheryKit
import Shared

final class SPMProjectSetupGuide: SetupGuideHelpers, ProjectSetupGuide {
    private let configuration: Configuration

    init(configuration: Configuration = .shared) {
        self.configuration = configuration
        super.init()
    }

    var projectKind: ProjectKind {
        .spm
    }

    var isSupported: Bool {
        SPM.isSupported
    }

    func perform() throws {
        let package = try SPM.Package.load()
        let selection = try selectTargets(in: package)

        if case let .some(targets) = selection {
            configuration.targets = targets
        }
    }

    var commandLineOptions: [String] {
        var options: [String] = []

        if !configuration.targets.isEmpty {
            options.append("--targets " + configuration.targets.map { "\"\($0)\"" }.joined(separator: ","))
        }

        return options
    }

    // MARK: - Private

    private func selectTargets(in package: SPM.Package) throws -> SetupSelection {
        let targets = package.swiftTargets

        guard !targets.isEmpty else {
            throw PeripheryError.guidedSetupError(message: "Failed to identify any targets in package \(package.name)")
        }

        print(colorize("Select build targets to analyze:", .bold))
        let targetNames = targets.map { $0.name }.sorted()
        return select(multiple: targetNames, allowAll: true)
    }

}

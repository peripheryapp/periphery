import Foundation

final class SPMProjectSetupGuide: SetupGuideHelpers, SetupGuide {
    static func make() -> Self {
        return self.init(configuration: inject())
    }

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
        super.init()
    }

    func perform() throws {
        let package = try SPM.Package.load()
        configuration.targets = try selectTargets(in: package)
    }

    var commandLineOptions: [String] {
        var options: [String] = []
        options.append("--targets " + configuration.targets.map { "\"\($0)\"" }.joined(separator: ","))
        return options
    }

    // MARK: - Private

    private func selectTargets(in package: SPM.Package) throws -> [String] {
        let targets = package.swiftTargets

        guard !targets.isEmpty else {
            throw PeripheryKitError.guidedSetupError(message: "Failed to identify any targets in package \(package.name)")
        }

        print(colorize("Select build targets to analyze:", .bold))
        let targetNames = targets.map { $0.name }.sorted()
        return select(multiple: targetNames, allowAll: true)
    }

}

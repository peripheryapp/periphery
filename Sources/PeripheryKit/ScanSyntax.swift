import Foundation
import Result
import PathKit

class ScanSyntax {
    public static func make() -> Self {
        return self.init(logger: inject(), configuration: inject())
    }

    private let logger: Logger
    private let configuration: Configuration

    public required init(logger: Logger, configuration: Configuration) {
        self.logger = logger
        self.configuration = configuration
    }

    func perform(_ path: String) throws -> ScanResult {
        let path = Path(path)
        var files: [Path]

        if !path.exists {
            throw PeripheryKitError.pathDoesNotExist(path: path.absolute().string)
        }

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Analyzing...\n")
        }

        if path.isDirectory {
            files = try path.recursiveChildren()
                .filter { $0.extension?.lowercased() == "swift" }
                .filter { $0.isFile }
                .map { $0.absolute() }
        } else {
            files = [path.absolute()]
        }

        for file in configuration.reportExclude {
            if let index = files.firstIndex(of: Path(file)) {
                files.remove(at: index)
            }
        }

        let analyzer = UnusedParameterAnalyzer()
        let jobPool = JobPool<Set<Parameter>>()

        let params = try jobPool.map(files) {
            self.logger.debug("[syntax] \($0)")
            return try analyzer.analyze(file: $0, parseProtocols: false)
        }.joined()

        let declarations = Set(params.map { $0.declaration })
        return ScanResult(declarations: declarations, graph: nil)
    }
}

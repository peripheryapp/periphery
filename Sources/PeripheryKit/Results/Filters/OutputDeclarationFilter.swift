import Configuration
import FilenameMatcher
import Foundation
import Logger
import SystemPackage
import Shared

public final class OutputDeclarationFilter {
    private let configuration: Configuration
    private let baseline: Baseline?
    private let logger: Logger
    private let shell: Shell
    private let diffProviderFactory: DiffProviderFactoryProtocol.Type

    public required init(
        configuration: Configuration,
        baseline: Baseline?,
        shell: Shell,
        logger: Logger,
        diffProviderFactory: DiffProviderFactoryProtocol.Type = DiffProviderFactory.self
    ) {
        self.configuration = configuration
        self.baseline = baseline
        self.logger = logger
        self.shell = shell
        self.diffProviderFactory = diffProviderFactory
    }

    public func filter(_ declarations: [ScanResult]) -> [ScanResult] {
        let diffProviders = diffProviderFactory.makeDiffProvider(
            configuration: configuration,
            shell: shell,
            baseline: baseline,
            logger: logger
        )
        
        var filteredDeclarations = declarations
        for diffProvider in diffProviders {
            filteredDeclarations = diffProvider.filter(filteredDeclarations)
        }
        
        return filteredDeclarations
    }
}

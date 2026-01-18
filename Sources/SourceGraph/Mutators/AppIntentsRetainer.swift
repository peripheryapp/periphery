import Configuration
import Foundation
import Shared

/// Retains types conforming to App Intents protocols.
///
/// Types conforming to these protocols are discovered and invoked by the system at runtime,
/// so they should not be reported as unused.
final class AppIntentsRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    /// USR prefix for Swift symbols from the AppIntents module.
    /// Swift USRs encode the module name with a length prefix: "s:<length><module_name>..."
    /// For AppIntents (10 characters), this becomes "s:10AppIntents".
    private static let appIntentsModuleUsrPrefix = "s:10AppIntents"

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        graph
            .declarations(ofKinds: [.class, .struct, .enum])
            .lazy
            .filter {
                $0.related.contains {
                    self.graph.isExternal($0) &&
                        $0.declarationKind == .protocol &&
                        $0.usr.hasPrefix(Self.appIntentsModuleUsrPrefix)
                }
            }
            .forEach { graph.markRetained($0) }
    }
}

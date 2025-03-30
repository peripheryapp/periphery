import Configuration
import Foundation
import Logger
import Shared

public final class SourceGraphMutatorRunner {
    private let mutators: [SourceGraphMutator.Type] = [
        // Must come before all others as we need to observe all references prior to any mutations.
        UnusedImportMarker.self,

        // Must come before ExtensionReferenceBuilder.
        AccessibilityCascader.self,
        ObjCAccessibleRetainer.self,
        // Must come before ExtensionReferenceBuilder so that it can detect redundant accessibility on extensions.
        RedundantExplicitPublicAccessibilityMarker.self,
        GenericClassAndStructConstructorReferenceBuilder.self,
        // Must come before ProtocolExtensionReferenceBuilder because it removes references
        // from the extension to the protocol, thus making them appear to be unknown.
        ExtensionReferenceBuilder.self,
        // Must come before ProtocolConformanceReferenceBuilder because it removes references to
        // conformed protocols, which CodingKeyEnumReferenceBuilder needs to inspect before removal.
        // It must also come after ExtensionReferenceBuilder as some types may declare conformance
        // to Codable in an extension.
        CodingKeyEnumReferenceBuilder.self,
        ProtocolExtensionReferenceBuilder.self,
        ProtocolConformanceReferenceBuilder.self,
        ExternalTypeProtocolConformanceReferenceRemover.self,
        ComplexPropertyAccessorReferenceBuilder.self,
        EnumCaseReferenceBuilder.self,
        DefaultConstructorReferenceBuilder.self,
        StructImplicitInitializerReferenceBuilder.self,

        DynamicMemberRetainer.self,
        UnusedParameterRetainer.self,
        AssetReferenceRetainer.self,
        EntryPointAttributeRetainer.self,
        PubliclyAccessibleRetainer.self,
        XCTestRetainer.self,
        SwiftTestingRetainer.self,
        SwiftUIRetainer.self,
        StringInterpolationAppendInterpolationRetainer.self,
        PropertyWrapperRetainer.self,
        ResultBuilderRetainer.self,
        CodablePropertyRetainer.self,
        ExternalOverrideRetainer.self,

        AncestralReferenceEliminator.self,
        AssignOnlyPropertyReferenceEliminator.self,

        UsedDeclarationMarker.self,
        RedundantProtocolMarker.self,
    ]

    private let graph: SourceGraph
    private let logger: ContextualLogger
    private let configuration: Configuration
    private let swiftVersion: SwiftVersion

    public required init(graph: SourceGraph, logger: Logger, configuration: Configuration, swiftVersion: SwiftVersion) {
        self.graph = graph
        self.logger = logger.contextualized(with: "mutator:run")
        self.configuration = configuration
        self.swiftVersion = swiftVersion

        SourceGraphDebugger(graph: graph).describeGraph()
    }

    public func perform() throws {
        for mutator in mutators {
            let elapsed = try Benchmark.measure {
                let interval = logger.beginInterval("mutator:run")
                try mutator.init(graph: graph, configuration: configuration, swiftVersion: swiftVersion).mutate()
                logger.endInterval(interval)
            }
            logger.debug("\(mutator) (\(elapsed)s)")
        }
    }
}

import Foundation
import Shared

public final class SourceGraphMutatorRunner {
    public static func perform(graph: SourceGraph) throws {
        try self.init(graph: graph).perform()
    }

    private let mutators: [SourceGraphMutator.Type] = [
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
        DefaultConstructorReferenceBuilder.self,
        ComplexPropertyAccessorReferenceBuilder.self,
        EnumCaseReferenceBuilder.self,
        LetShorthandPropertyReferenceBuilder.self,

        UnusedParameterRetainer.self,
        AssetReferenceRetainer.self,
        EntryPointAttributeRetainer.self,
        PubliclyAccessibleRetainer.self,
        XCTestRetainer.self,
        SwiftUIRetainer.self,
        EncodablePropertyRetainer.self,
        StringInterpolationAppendInterpolationRetainer.self,
        PropertyWrapperRetainer.self,
        ResultBuilderRetainer.self,
        CapitalSelfFunctionCallRetainer.self,

        PlainExtensionEliminator.self,
        AncestralReferenceEliminator.self,
        AssignOnlyPropertyReferenceEliminator.self,

        UsedDeclarationMarker.self,
        RedundantProtocolMarker.self
    ]

    private let graph: SourceGraph
    private let logger: ContextualLogger
    private let configuration: Configuration

    required init(graph: SourceGraph, logger: Logger = .init(), configuration: Configuration = .shared) {
        self.graph = graph
        self.logger = logger.contextualized(with: "mutator:run")
        self.configuration = configuration
    }

    func perform() throws {
        let interval = logger.beginInterval("mutator:run")

        for mutator in mutators {
            let elapsed = try Benchmark.measure {
                try mutator.init(graph: graph, configuration: configuration).mutate()
            }
            logger.debug("\(mutator) (\(elapsed)s)")
        }

        logger.endInterval(interval)
    }
}

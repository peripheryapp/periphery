import Foundation
import Shared

public final class SourceGraphMutatorRunner {
    public static func perform(graph: SourceGraph) throws {
        try make(graph: graph).perform()
    }

    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph, logger: inject())
    }

    private let mutators: [SourceGraphMutator.Type] = [
        // Must come before ExtensionReferenceBuilder.
        AccessibilityCascader.self,

        // Must come before ExtensionReferenceBuilder so that it can detect redundant accessibility on extensions.
        RedundantExplicitPublicAccessibilityMarker.self,

        // Must come before ProtocolExtensionReferenceBuilder because it removes references
        // from the extension to the protocol, thus making them appear to be unknown.
        UnknownTypeExtensionRetainer.self,

        GenericClassAndStructConstructorReferenceBuilder.self,
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

        UnusedParameterRetainer.self,
        AssetReferenceRetainer.self,
        EntryPointAttributeRetainer.self,
        PubliclyAccessibleRetainer.self,
        ObjCAccessibleRetainer.self,
        XCTestRetainer.self,
        SwiftUIRetainer.self,
        EncodablePropertyRetainer.self,
        StringInterpolationAppendInterpolationRetainer.self,
        PropertyWrapperRetainer.self,
        ResultBuilderRetainer.self,

        PlainExtensionEliminator.self,
        AncestralReferenceEliminator.self,
        AssignOnlyPropertyReferenceEliminator.self,

        UsedDeclarationMarker.self,
        RedundantProtocolMarker.self,
        LetShorthandPropertyReferenceMarker.self
    ]

    private let graph: SourceGraph
    private let logger: ContextualLogger

    required init(graph: SourceGraph, logger: Logger) {
        self.graph = graph
        self.logger = logger.contextualized(with: "mutator:run")
    }

    func perform() throws {
        for mutator in mutators {
            let elapsed = try Benchmark.measure {
                try mutator.make(graph: graph).mutate()
            }
            logger.debug("\(mutator) (\(elapsed)s)")
        }
    }
}

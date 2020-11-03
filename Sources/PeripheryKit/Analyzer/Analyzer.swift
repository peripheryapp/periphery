import Foundation

final class Analyzer {
    static func perform(graph: SourceGraph) throws {
        try make(graph: graph).perform()
    }

    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph,
                         configuration: inject(),
                         logger: inject())
    }

    private let visitors: [SourceGraphVisitor.Type] = [
        ObjcMembersAttributeBuilder.self,

        // Must come before ExtensionReferenceBuilder.
        AccessibilityCascader.self,

        // Must come before ProtocolConformanceReferenceBuilder because it removes references to
        // conformed protocols, which CodingKeyEnumReferenceBuilder needs to inspect before removal.
        CodingKeyEnumReferenceBuilder.self,

        // Must come before ProtocolExtensionReferenceBuilder because it removes references
        // from the extension to the protocol, thus making them appear to be unknown.
        UnknownTypeExtensionRetainer.self,

        GenericClassConstructorReferenceBuilder.self,
        ExtensionReferenceBuilder.self,
        ProtocolExtensionReferenceBuilder.self,
        ProtocolConformanceReferenceBuilder.self,
        DefaultConstructorReferenceBuilder.self,
        ComplexPropertyAccessorReferenceBuilder.self,
        EnumCaseReferenceBuilder.self,
        AssociatedTypeTypeAliasReferenceBuilder.self,

        UnusedParameterRetainer.self,
        XibReferenceRetainer.self,
        InfoPlistReferenceRetainer.self,
        ApplicationMainRetainer.self,
        MainEntryPointRetainer.self,
        PubliclyAccessibleRetainer.self,
        ObjCAccessibleRetainer.self,
        XCTestRetainer.self,
        SwiftUIRetainer.self,
        StructImplicitConstructorPropertyRetainer.self,
        StringInterpolationAppendInterpolationRetainer.self,

        PlainExtensionEliminator.self,
        AncestralReferenceEliminator.self,

        DeclarationMarker.self
    ]

    private let configuration: Configuration
    private let graph: SourceGraph
    private let logger: Logger

    required init(graph: SourceGraph, configuration: Configuration, logger: Logger) {
        self.graph = graph
        self.configuration = configuration
        self.logger = logger
    }

    func perform() throws {
        for visitor in visitors {
            let elapsed = try Benchmark.measure {
                try graph.accept(visitor: visitor)
            }
            logger.debug("[analyze:visit] \(visitor) (\(elapsed)s)")
        }
    }
}

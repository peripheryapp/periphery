import Foundation
import Shared
import SwiftSyntax

final class PropertyVisitor: PeripherySyntaxVisitor {
    static func make(sourceLocationBuilder: SourceLocationBuilder) -> Self {
        self.init(sourceLocationBuilder: sourceLocationBuilder, logger: inject())
    }

    typealias Result = (
        location: SourceLocation,
        type: String?,
        typeLocations: Set<SourceLocation>
    )

    private let sourceLocationBuilder: SourceLocationBuilder
    private let typeSyntaxInspector: TypeSyntaxInspector
    private let logger: Logger
    private(set) var results: [Result] = []

    var resultsByLocation: [SourceLocation: Result] {
        results.reduce(into: [SourceLocation: Result]()) { (dict, result) in
            dict[result.location] = result
        }
    }

    init(sourceLocationBuilder: SourceLocationBuilder, logger: Logger) {
        self.sourceLocationBuilder = sourceLocationBuilder
        self.typeSyntaxInspector = .init(sourceLocationBuilder: sourceLocationBuilder)
        self.logger = logger
    }

    func visit(_ node: VariableDeclSyntax) {
        for binding in node.bindings {
            if binding.pattern.is(IdentifierPatternSyntax.self) {
                let location = sourceLocationBuilder.location(at: binding.positionAfterSkippingLeadingTrivia)

                if let typeSyntax = binding.typeAnnotation?.type {
                    let type = typeSyntaxInspector.type(for: typeSyntax)
                    let typeLocations = typeSyntaxInspector.typeLocations(for: typeSyntax)
                    results.append((location, type, typeLocations))
                } else {
                    results.append((location, nil, []))
                }
            } else if let tuplePatternSyntax = binding.pattern.as(TuplePatternSyntax.self) {
                // Destructuring binding.
                let locations = tuplePatternSyntax.elements.map { sourceLocationBuilder.location(at: $0.positionAfterSkippingLeadingTrivia) }

                if let typeSyntax = binding.typeAnnotation?.type {
                    if let tupleType = typeSyntax.as(TupleTypeSyntax.self) {
                        // Inspect elements individually, and associate each type with its corresponding identifier.
                        let elementTypeLocations = tupleType.elements.map { elem -> (String, Set<SourceLocation>) in
                            let type = typeSyntaxInspector.type(for: elem.type)
                            let typeLocations = typeSyntaxInspector.typeLocations(for: elem.type)
                            return (type, typeLocations)
                        }

                        for (location, (type, typeLocations)) in zip(locations, elementTypeLocations) {
                            results.append((location, type, typeLocations))
                        }
                    } else {
                        // Destructuring without a tuple type?
                        let location = sourceLocationBuilder.location(at: binding.positionAfterSkippingLeadingTrivia)
                        logger.debug("Cannot handle destructuring property binding with non-tuple type at '\(location)'.")
                    }
                } else {
                    for location in locations {
                        results.append((location, nil, []))
                    }
                }
            } else {
                let location = sourceLocationBuilder.location(at: binding.positionAfterSkippingLeadingTrivia)
                results.append((location, nil, []))
            }
        }
    }
}

import Foundation
import Shared
import PathKit
import SwiftSyntax

final class PropertyMetadataVisitor: PeripherySyntaxVisitor {
    typealias Result = (
        location: SourceLocation,
        type: String?,
        typeLocations: [SourceLocation]?
    )

    let file: Path
    let locationConverter: SourceLocationConverter

    private(set) var results: [Result] = []

    var resultsByTypeLocation: [SourceLocation: [Result]] {
        results.reduce(into: [SourceLocation: [Result]]()) { (dict, result) in
            result.typeLocations?.forEach { dict[$0, default: []].append(result) }
        }
    }

    var resultsByLocation: [SourceLocation: Result] {
        results.reduce(into: [SourceLocation: Result]()) { (dict, result) in
            dict[result.location] = result
        }
    }

    required init(file: Path, locationConverter: SourceLocationConverter) {
        self.file = file
        self.locationConverter = locationConverter
    }

    func visit(_ node: VariableDeclSyntax) {
        for binding in node.bindings {
            if binding.pattern.is(IdentifierPatternSyntax.self) {
                let location = sourceLocation(of: binding.positionAfterSkippingLeadingTrivia)

                if let typeAnnotation = binding.typeAnnotation {
                    let type = PropertyTypeSanitizer.sanitize(typeAnnotation.type.description)
                    let typeLocations = buildTypeLocations(for: typeAnnotation.type)

                    results.append((location, type, typeLocations))
                } else {
                    results.append((location, nil, nil))
                }
            } else if let tuple = binding.pattern.as(TuplePatternSyntax.self) {
                let locations = tuple.elements.map { sourceLocation(of: $0.positionAfterSkippingLeadingTrivia) }
                let types: [String?]
                let typeLocations: [[SourceLocation]?]

                if let typeAnnotation = binding.typeAnnotation?.type.as(TupleTypeSyntax.self) {
                    types = typeAnnotation.elements.compactMap { $0.type.description }.map { PropertyTypeSanitizer.sanitize($0) }
                    typeLocations = typeAnnotation.elements.map { buildTypeLocations(for: $0.type) }
                } else {
                    types = Array(repeating: nil, count: locations.count)
                    typeLocations = Array(repeating: nil, count: locations.count)
                }

                for (location, (type, typeMemberLocations)) in zip(locations, zip(types, typeLocations)) {
                    results.append((location, type, typeMemberLocations))
                }
            } else {
                let location = sourceLocation(of: binding.positionAfterSkippingLeadingTrivia)
                results.append((location, nil, nil))
            }
        }
    }

    // MARK: - Private

    private func buildTypeLocations(for type: TypeSyntax) -> [SourceLocation] {
        if let memberType = type.as(MemberTypeIdentifierSyntax.self) {
            return buildTypeLocations(for: memberType.baseType) + [sourceLocation(of: memberType.name.positionAfterSkippingLeadingTrivia)]
        }

        return [sourceLocation(of: type.positionAfterSkippingLeadingTrivia)]
    }
}

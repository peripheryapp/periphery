import Foundation
import SwiftSyntax
import PathKit
import Shared

final class ConformableVisitor: PeripherySyntaxVisitor {
    static func make(sourceLocationBuilder: SourceLocationBuilder) -> Self {
        self.init(sourceLocationBuilder: sourceLocationBuilder)
    }

    typealias Result = (
        location: SourceLocation,
        genericParameterLocations: Set<SourceLocation>,
        genericConformanceRequirementLocations: Set<SourceLocation>
    )

    private let sourceLocationBuilder: SourceLocationBuilder
    private let typeSyntaxInspector: TypeSyntaxInspector
    private(set) var results: [Result] = []

    var resultsByLocation: [SourceLocation: Result] {
        results.reduce(into: [SourceLocation: Result]()) { (dict, result) in
            dict[result.location] = result
        }
    }

    init(sourceLocationBuilder: SourceLocationBuilder) {
        self.sourceLocationBuilder = sourceLocationBuilder
        self.typeSyntaxInspector = .init(sourceLocationBuilder: sourceLocationBuilder)
    }

    func visit(_ node: ClassDeclSyntax) {
        visit(
            node.genericParameterClause,
            node.genericWhereClause,
            for: node.identifier
        )
    }

    func visit(_ node: StructDeclSyntax) {
        visit(
            node.genericParameterClause,
            node.genericWhereClause,
            for: node.identifier
        )
    }

    func visit(_ node: EnumDeclSyntax) {
        visit(
            node.genericParameters,
            node.genericWhereClause,
            for: node.identifier
        )
    }

    // MARK: - Private

    private func visit(
        _ genericParameterClause: GenericParameterClauseSyntax?,
        _ genericWhereClause: GenericWhereClauseSyntax?,
        for identifier: TokenSyntax)
    {
        var genericParameterLocations: Set<SourceLocation> = []
        var genericConformanceRequirementLocations: Set<SourceLocation> = []

        if let genericParameterList = genericParameterClause?.genericParameterList {
            for param in genericParameterList {
                if let inheritedType = param.inheritedType {
                    genericParameterLocations.formUnion(typeSyntaxInspector.typeLocations(for: inheritedType))
                }
            }
        }

        if let requirementList = genericWhereClause?.requirementList {
            for requirement in requirementList {
                if let conformanceRequirementType = requirement.body.as(ConformanceRequirementSyntax.self) {
                    genericConformanceRequirementLocations.formUnion(typeSyntaxInspector.typeLocations(for: conformanceRequirementType.rightTypeIdentifier))
                }
            }
        }

        let location = sourceLocationBuilder.location(at: identifier.positionAfterSkippingLeadingTrivia)

        results.append((location,
                        genericParameterLocations,
                        genericConformanceRequirementLocations))
    }
}

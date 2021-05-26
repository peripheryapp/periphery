import Foundation
import SwiftSyntax
import PathKit
import Shared

final class FunctionVisitor: PeripherySyntaxVisitor {
    static func make(sourceLocationBuilder: SourceLocationBuilder) -> Self {
        self.init(sourceLocationBuilder: sourceLocationBuilder)
    }

    typealias Result = (
        location: SourceLocation,
        parameterTypeLocations: Set<SourceLocation>,
        returnTypeLocations: Set<SourceLocation>,
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

    func visit(_ node: FunctionDeclSyntax) {
        let location = sourceLocationBuilder.location(at: node.identifier.positionAfterSkippingLeadingTrivia)
        var returnTypeLocations: Set<SourceLocation> = []
        var parameterTypeLocations: Set<SourceLocation> = []
        var genericParameterLocations: Set<SourceLocation> = []
        var genericConformanceRequirementLocations: Set<SourceLocation> = []

        if let returnTypeSyntax = node.signature.output?.returnType {
            if let someReturnType = returnTypeSyntax.as(SomeTypeSyntax.self) {
                returnTypeLocations = typeSyntaxInspector.typeLocations(for: someReturnType.baseType)
            } else {
                returnTypeLocations = typeSyntaxInspector.typeLocations(for: returnTypeSyntax)
            }
        }

        for functionParameterSyntax in node.signature.input.parameterList {
            if let typeSyntax = functionParameterSyntax.type {
                parameterTypeLocations.formUnion(typeSyntaxInspector.typeLocations(for: typeSyntax))
            }
        }

        if let genericParameterList = node.genericParameterClause?.genericParameterList {
            for param in genericParameterList {
                if let inheritedType = param.inheritedType {
                    genericParameterLocations.formUnion(typeSyntaxInspector.typeLocations(for: inheritedType))
                }
            }
        }

        if let requirementList = node.genericWhereClause?.requirementList {
            for requirement in requirementList {
                if let conformanceRequirementType = requirement.body.as(ConformanceRequirementSyntax.self) {
                    genericConformanceRequirementLocations.formUnion(typeSyntaxInspector.typeLocations(for: conformanceRequirementType.rightTypeIdentifier))
                }
            }
        }

        results.append((location,
                        parameterTypeLocations,
                        returnTypeLocations,
                        genericParameterLocations,
                        genericConformanceRequirementLocations))
    }
}

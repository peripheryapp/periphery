import Foundation
import SwiftSyntax
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
        results.append((sourceLocationBuilder.location(at: node.identifier.positionAfterSkippingLeadingTrivia),
                        typeLocations(for: node.signature.input),
                        typeLocations(for: node.signature.output),
                        typeLocations(for: node.genericParameterClause),
                        typeLocations(for: node.genericWhereClause)))
    }

    func visit(_ node: InitializerDeclSyntax) {
        results.append((sourceLocationBuilder.location(at: node.initKeyword.positionAfterSkippingLeadingTrivia),
                        typeLocations(for: node.parameters),
                        [],
                        typeLocations(for: node.genericParameterClause),
                        typeLocations(for: node.genericWhereClause)))
    }

    func visit(_ node: SubscriptDeclSyntax) {
        results.append((sourceLocationBuilder.location(at: node.subscriptKeyword.positionAfterSkippingLeadingTrivia),
                        typeLocations(for: node.indices),
                        typeLocations(for: node.result),
                        typeLocations(for: node.genericParameterClause),
                        typeLocations(for: node.genericWhereClause)))
    }

    // MARK: - Private

    private func typeLocations(for parameterClause: ParameterClauseSyntax) -> Set<SourceLocation> {
        return Set(parameterClause.parameterList.flatMap { parameter -> Set<SourceLocation> in
            if let typeSyntax = parameter.type {
                return typeSyntaxInspector.typeLocations(for: typeSyntax)
            }

            return []
        })
    }

    private func typeLocations(for returnClause: ReturnClauseSyntax?) -> Set<SourceLocation> {
        guard let returnTypeSyntax = returnClause?.returnType else { return [] }

        if let someReturnType = returnTypeSyntax.as(SomeTypeSyntax.self) {
            return typeSyntaxInspector.typeLocations(for: someReturnType.baseType)
        }

        return typeSyntaxInspector.typeLocations(for: returnTypeSyntax)
    }

    private func typeLocations(for genericParameterClause: GenericParameterClauseSyntax?) -> Set<SourceLocation> {
        guard let genericParameterClause = genericParameterClause else { return [] }

        return Set(genericParameterClause.genericParameterList.flatMap { parameter -> Set<SourceLocation> in
            if let inheritedType = parameter.inheritedType {
                return typeSyntaxInspector.typeLocations(for: inheritedType)
            }

            return []
        })
    }

    private func typeLocations(for genericWhereClause: GenericWhereClauseSyntax?) -> Set<SourceLocation> {
        guard let genericWhereClause = genericWhereClause else { return [] }

        return Set(genericWhereClause.requirementList.flatMap { requirement -> Set<SourceLocation> in
            if let conformanceRequirementType = requirement.body.as(ConformanceRequirementSyntax.self) {
                return typeSyntaxInspector.typeLocations(for: conformanceRequirementType.rightTypeIdentifier)
            }

            return []
        })
    }
}

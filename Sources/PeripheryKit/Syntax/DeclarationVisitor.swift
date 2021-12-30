import Foundation
import SwiftSyntax

final class DeclarationVisitor: PeripherySyntaxVisitor {
    static func make(sourceLocationBuilder: SourceLocationBuilder) -> Self {
        self.init(sourceLocationBuilder: sourceLocationBuilder)
    }

    typealias Result = (
        location: SourceLocation,
        accessibility: Accessibility?,
        modifiers: [String],
        attributes: [String],
        commentCommands: [CommentCommand],
        variableType: String?,
        variableTypeLocations: Set<SourceLocation>,
        parameterTypeLocations: Set<SourceLocation>,
        returnTypeLocations: Set<SourceLocation>,
        inheritedTypeLocations: Set<SourceLocation>,
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
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            inheritanceClause: node.inheritanceClause,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: ProtocolDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            inheritanceClause: node.inheritanceClause,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: StructDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: EnumDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            genericParameterClause: node.genericParameters,
            genericWhereClause: node.genericWhereClause,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: EnumCaseDeclSyntax) {
        for element in node.elements {
            parse(
                modifiers: node.modifiers,
                attributes: node.attributes,
                trivia: node.leadingTrivia,
                parameterClause: element.associatedValue,
                at: element.identifier.positionAfterSkippingLeadingTrivia
            )
        }
    }

    func visit(_ node: ExtensionDeclSyntax) {
        var position = node.extendedType.positionAfterSkippingLeadingTrivia

        if let memberType = node.extendedType.as(MemberTypeIdentifierSyntax.self) {
            position = memberType.name.positionAfterSkippingLeadingTrivia
        }

        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: position
        )
    }

    func visit(_ node: FunctionDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            parameterClause: node.signature.input,
            returnClause: node.signature.output,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: InitializerDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            parameterClause: node.parameters,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            at: node.initKeyword.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: DeinitializerDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.deinitKeyword.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: SubscriptDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            parameterClause: node.indices,
            returnClause: node.result,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            at: node.subscriptKeyword.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: VariableDeclSyntax) {
        for binding in node.bindings {
            if binding.pattern.is(IdentifierPatternSyntax.self) {
                parse(
                    modifiers: node.modifiers,
                    attributes: node.attributes,
                    trivia: node.leadingTrivia,
                    variableType: binding.typeAnnotation?.type,
                    at: binding.positionAfterSkippingLeadingTrivia
                )
            } else if let tuplePatternSyntax = binding.pattern.as(TuplePatternSyntax.self) {
                // Destructuring binding.
                let positions = tuplePatternSyntax.elements.map { $0.positionAfterSkippingLeadingTrivia }

                if let typeSyntax = binding.typeAnnotation?.type {
                    if let tupleType = typeSyntax.as(TupleTypeSyntax.self) {
                        // Inspect elements individually, and associate each type with its corresponding identifier.
                        for (position, elem) in zip(positions, tupleType.elements) {
                            parse(
                                modifiers: node.modifiers,
                                attributes: node.attributes,
                                trivia: node.leadingTrivia,
                                variableType: elem.type,
                                at: position
                            )
                        }
                    }
                } else {
                    for position in positions {
                        parse(
                            modifiers: node.modifiers,
                            attributes: node.attributes,
                            trivia: node.leadingTrivia,
                            at: position
                        )
                    }
                }
            } else {
                parse(
                    modifiers: node.modifiers,
                    attributes: node.attributes,
                    trivia: node.leadingTrivia,
                    at: binding.positionAfterSkippingLeadingTrivia
                )
            }
        }
    }

    func visit(_ node: TypealiasDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: AssociatedtypeDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: OperatorDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: PrecedenceGroupDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    // MARK: - Private

    private func parse(
        modifiers: ModifierListSyntax?,
        attributes: AttributeListSyntax?,
        trivia: Trivia?,
        variableType: TypeSyntax? = nil,
        parameterClause: ParameterClauseSyntax? = nil,
        returnClause: ReturnClauseSyntax? = nil,
        inheritanceClause: TypeInheritanceClauseSyntax? = nil,
        genericParameterClause: GenericParameterClauseSyntax? = nil,
        genericWhereClause: GenericWhereClauseSyntax? = nil,
        at position: AbsolutePosition
    ) {
        let modifierNames = modifiers?.withoutTrivia().map { $0.name.text } ?? []
        let accessibility = modifierNames.mapFirst { Accessibility(rawValue: $0) }
        let attributeNames = attributes?.withoutTrivia().compactMap {
            AttributeSyntax($0)?.attributeName.text ?? CustomAttributeSyntax($0)?.attributeName.firstToken?.text
        } ?? []
        let location = sourceLocationBuilder.location(at: position)

        results.append((
            location,
            accessibility,
            modifierNames,
            attributeNames,
            CommentCommand.parseCommands(in: trivia),
            type(for: variableType),
            typeLocations(for: variableType),
            typeLocations(for: parameterClause),
            typeLocations(for: returnClause),
            typeLocations(for: inheritanceClause),
            typeLocations(for: genericParameterClause),
            typeLocations(for: genericWhereClause)
        ))
    }

    private func type(for typeSyntax: TypeSyntax?) -> String? {
        guard let typeSyntax = typeSyntax else { return nil }
        return typeSyntaxInspector.type(for: typeSyntax)
    }

    private func typeLocations(for typeSyntax: TypeSyntax?) -> Set<SourceLocation> {
        guard let typeSyntax = typeSyntax else { return [] }
        return typeSyntaxInspector.typeLocations(for: typeSyntax)
    }

    private func typeLocations(for clause: ParameterClauseSyntax?) -> Set<SourceLocation> {
        guard let clause = clause else { return [] }

        return clause.parameterList.reduce(into: .init(), { result, param in
            if let typeSyntax = param.type {
                result.formUnion(typeSyntaxInspector.typeLocations(for: typeSyntax))
            }
        })
    }

    private func typeLocations(for clause: ReturnClauseSyntax?) -> Set<SourceLocation> {
        guard let returnTypeSyntax = clause?.returnType else { return [] }

        if let someReturnType = returnTypeSyntax.as(SomeTypeSyntax.self) {
            return typeSyntaxInspector.typeLocations(for: someReturnType.baseType)
        }

        return typeSyntaxInspector.typeLocations(for: returnTypeSyntax)
    }

    private func typeLocations(for clause: GenericParameterClauseSyntax?) -> Set<SourceLocation> {
        guard let clause = clause else { return [] }

        return clause.genericParameterList.reduce(into: .init()) { result, param in
            if let inheritedType = param.inheritedType {
                result.formUnion(typeSyntaxInspector.typeLocations(for: inheritedType))
            }
        }
    }

    private func typeLocations(for clause: GenericWhereClauseSyntax?) -> Set<SourceLocation> {
        guard let clause = clause else { return [] }

        return clause.requirementList.reduce(into: .init()) { result, requirement in
            if let conformanceRequirementType = requirement.body.as(ConformanceRequirementSyntax.self) {
                result.formUnion(typeSyntaxInspector.typeLocations(for: conformanceRequirementType.rightTypeIdentifier))
            }
        }
    }

    private func typeLocations(for clause: TypeInheritanceClauseSyntax?) -> Set<SourceLocation> {
        guard let clause = clause else { return [] }

        return clause.inheritedTypeCollection.reduce(into: .init()) { result, type in
            result.formUnion(typeSyntaxInspector.typeLocations(for: type.typeName))
        }
    }
}

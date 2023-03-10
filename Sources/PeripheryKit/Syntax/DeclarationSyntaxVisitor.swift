import Foundation
import SwiftSyntax

final class DeclarationSyntaxVisitor: PeripherySyntaxVisitor {
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
        genericConformanceRequirementLocations: Set<SourceLocation>,
        letShorthandIdentifiers: Set<String>,
        hasCapitalSelfFunctionCall: Bool
    )

    var letShorthandWorkaroundEnabled: Bool = false

    private let sourceLocationBuilder: SourceLocationBuilder
    private let typeSyntaxInspector: TypeSyntaxInspector
    private(set) var results: [Result] = []
    private var letShorthandIdentifiers: Set<String> = []
    private var didVisitCapitalSelfFunctionCall: Bool = false
    private var declarationBodyStackDepth = 0

    var resultsByLocation: [SourceLocation: Result] {
        results.reduce(into: [SourceLocation: Result]()) { (dict, result) in
            dict[result.location] = result
        }
    }

    init(sourceLocationBuilder: SourceLocationBuilder) {
        self.sourceLocationBuilder = sourceLocationBuilder
        self.typeSyntaxInspector = .init(sourceLocationBuilder: sourceLocationBuilder)
    }

    func visitPost(_ node: ClassDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            inheritanceClause: node.inheritanceClause,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            consumeCapitalSelfFunctionCalls: true,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: ProtocolDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            inheritanceClause: node.inheritanceClause,
            genericWhereClause: node.genericWhereClause,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: StructDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            inheritanceClause: node.inheritanceClause,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            consumeCapitalSelfFunctionCalls: true,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: EnumDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            inheritanceClause: node.inheritanceClause,
            genericParameterClause: node.genericParameters,
            genericWhereClause: node.genericWhereClause,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: EnumCaseDeclSyntax) {
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

    func visitPost(_ node: ExtensionDeclSyntax) {
        var position = node.extendedType.positionAfterSkippingLeadingTrivia

        if let memberType = node.extendedType.as(MemberTypeIdentifierSyntax.self) {
            position = memberType.name.positionAfterSkippingLeadingTrivia
        }

        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            inheritanceClause: node.inheritanceClause,
            genericWhereClause: node.genericWhereClause,
            consumeCapitalSelfFunctionCalls: true,
            at: position
        )
    }

    func visit(_: FunctionDeclSyntax) {
        declarationBodyStackDepth += 1
    }

    func visitPost(_ node: FunctionDeclSyntax) {
        declarationBodyStackDepth -= 1

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

    func visit(_: InitializerDeclSyntax) {
        declarationBodyStackDepth += 1
    }

    func visitPost(_ node: InitializerDeclSyntax) {
        declarationBodyStackDepth -= 1

        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            parameterClause: node.signature.input,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            at: node.initKeyword.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_: DeinitializerDeclSyntax) {
        declarationBodyStackDepth += 1
    }

    func visitPost(_ node: DeinitializerDeclSyntax) {
        declarationBodyStackDepth -= 1

        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.deinitKeyword.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_: SubscriptDeclSyntax) {
        declarationBodyStackDepth += 1
    }

    func visitPost(_ node: SubscriptDeclSyntax) {
        declarationBodyStackDepth -= 1

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

    func visit(_: VariableDeclSyntax) {
        declarationBodyStackDepth += 1
    }

    func visitPost(_ node: VariableDeclSyntax) {
        declarationBodyStackDepth -= 1

        for binding in node.bindings {
            if binding.pattern.is(IdentifierPatternSyntax.self) {
                let closureSignature = binding.initializer?.value.as(ClosureExprSyntax.self)?.signature
                let closureParameters = closureSignature?.input?.as(ParameterClauseSyntax.self)
                parse(
                    modifiers: node.modifiers,
                    attributes: node.attributes,
                    trivia: node.leadingTrivia,
                    variableType: binding.typeAnnotation?.type,
                    parameterClause: closureParameters,
                    returnClause: closureSignature?.output,
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

    func visitPost(_ node: TypealiasDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            variableType: node.initializer.value,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: AssociatedtypeDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            inheritanceClause: node.inheritanceClause,
            genericWhereClause: node.genericWhereClause,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: OperatorDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: PrecedenceGroupDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: OptionalBindingConditionSyntax) {
        guard letShorthandWorkaroundEnabled else { return }

        guard node.initializer == nil,
              let identifier = node.pattern.as(IdentifierPatternSyntax.self)?.identifier,
              let parentStmt = node.parent?.parent?.parent,
              (parentStmt.is(IfExprSyntax.self) || parentStmt.is(GuardStmtSyntax.self))
        else { return }
        letShorthandIdentifiers.insert(identifier.text)
    }

    func visit(_ node: FunctionCallExprSyntax) {
        if let identifierExpr = node.calledExpression.as(IdentifierExprSyntax.self),
           identifierExpr.identifier.tokenKind == .keyword(.Self) {
            didVisitCapitalSelfFunctionCall = true
        }
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
        consumeCapitalSelfFunctionCalls: Bool = false,
        at position: AbsolutePosition
    ) {
        let modifierNames = modifiers?.map { $0.name.text } ?? []
        let accessibility = modifierNames.mapFirst { Accessibility(rawValue: $0) }
        let attributeNames = attributes?.compactMap {
            AttributeSyntax($0)?.attributeName.trimmedDescription ?? AttributeSyntax($0)?.attributeName.firstToken?.text
        } ?? []
        let location = sourceLocationBuilder.location(at: position)
        var letShorthandIdentifiers = Set<String>()

        // Only associate let shorthand identifiers in nested code blocks with the top-most
        // code block.
        if declarationBodyStackDepth == 0 {
            letShorthandIdentifiers = self.letShorthandIdentifiers
            self.letShorthandIdentifiers.removeAll()
        }

        var didVisitCapitalSelfFunctionCall = false
        if consumeCapitalSelfFunctionCalls {
            didVisitCapitalSelfFunctionCall = self.didVisitCapitalSelfFunctionCall
            self.didVisitCapitalSelfFunctionCall = false
        }

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
            typeLocations(for: genericWhereClause),
            letShorthandIdentifiers,
            didVisitCapitalSelfFunctionCall
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

        if let someReturnType = returnTypeSyntax.as(ConstrainedSugarTypeSyntax.self) {
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

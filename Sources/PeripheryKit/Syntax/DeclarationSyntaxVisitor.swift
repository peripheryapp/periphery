import Foundation
import SwiftSyntax
import SourceGraph

final class DeclarationSyntaxVisitor: PeripherySyntaxVisitor {
    typealias Result = (
        location: Location,
        accessibility: Accessibility?,
        modifiers: [String],
        attributes: [String],
        commentCommands: [CommentCommand],
        variableType: String?,
        variableTypeLocations: Set<Location>,
        parameterTypeLocations: Set<Location>,
        returnTypeLocations: Set<Location>,
        inheritedTypeLocations: Set<Location>,
        genericParameterLocations: Set<Location>,
        genericConformanceRequirementLocations: Set<Location>,
        variableInitFunctionCallLocations: Set<Location>,
        functionCallMetatypeArgumentLocations: Set<Location>,
        typeInitializerLocations: Set<Location>,
        hasCapitalSelfFunctionCall: Bool,
        hasGenericFunctionReturnedMetatypeParameters: Bool
    )

    private let sourceLocationBuilder: SourceLocationBuilder
    private let typeSyntaxInspector: TypeSyntaxInspector
    private(set) var results: [Result] = []
    private var didVisitCapitalSelfFunctionCall: Bool = false

    var resultsByLocation: [Location: Result] {
        results.reduce(into: [Location: Result]()) { (dict, result) in
            dict[result.location] = result
        }
    }

    init(sourceLocationBuilder: SourceLocationBuilder) {
        self.sourceLocationBuilder = sourceLocationBuilder
        self.typeSyntaxInspector = .init(sourceLocationBuilder: sourceLocationBuilder)
    }

    func visitPost(_ node: ActorDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            inheritanceClause: node.inheritanceClause,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            consumeCapitalSelfFunctionCalls: true,
            at: node.name.positionAfterSkippingLeadingTrivia
        )
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
            at: node.name.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: ProtocolDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            inheritanceClause: node.inheritanceClause,
            genericWhereClause: node.genericWhereClause,
            at: node.name.positionAfterSkippingLeadingTrivia
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
            at: node.name.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: EnumDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            inheritanceClause: node.inheritanceClause,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            at: node.name.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: EnumCaseDeclSyntax) {
        for element in node.elements {
            parse(
                modifiers: node.modifiers,
                attributes: node.attributes,
                trivia: node.leadingTrivia,
                enumCaseParameterClause: element.parameterClause,
                at: element.name.positionAfterSkippingLeadingTrivia
            )
        }
    }

    func visitPost(_ node: ExtensionDeclSyntax) {
        var position = node.extendedType.positionAfterSkippingLeadingTrivia

        if let memberType = node.extendedType.as(MemberTypeSyntax.self) {
            position = memberType.name.positionAfterSkippingLeadingTrivia
        } else if let genericArgumentClause = node.extendedType.as(IdentifierTypeSyntax.self)?.genericArgumentClause {
            // Generic protocol extensions in the form `extension Foo<Type>` have incorrect locations in the index store.
            // This results in syntax metadata not being applied to the declaration due to the location mismatch. To
            // workaround this, parse this node with the incorrect location.
            position = genericArgumentClause.rightAngle.positionAfterSkippingLeadingTrivia
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

    func visitPost(_ node: FunctionDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            parameterClause: node.signature.parameterClause,
            returnClause: node.signature.returnClause,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            at: node.name.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: InitializerDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            parameterClause: node.signature.parameterClause,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            at: node.initKeyword.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: DeinitializerDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.deinitKeyword.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: SubscriptDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            parameterClause: node.parameterClause,
            returnClause: node.returnClause,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            at: node.subscriptKeyword.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: VariableDeclSyntax) {
        for binding in node.bindings {
            if binding.pattern.is(IdentifierPatternSyntax.self) {
                let closureSignature = binding.initializer?.value.as(ClosureExprSyntax.self)?.signature
                let closureParameters = closureSignature?.parameterClause?.as(ClosureParameterClauseSyntax.self)
                let functionCallExpr = binding.initializer?.value.as(FunctionCallExprSyntax.self)
                parse(
                    modifiers: node.modifiers,
                    attributes: node.attributes,
                    trivia: node.leadingTrivia,
                    variableType: binding.typeAnnotation?.type,
                    closureParameterClause: closureParameters,
                    returnClause: closureSignature?.returnClause,
                    variableInitFunctionCallExpr: functionCallExpr,
                    at: binding.positionAfterSkippingLeadingTrivia
                )
            } else if let tuplePatternSyntax = binding.pattern.as(TuplePatternSyntax.self) {
                visitVariableTupleBinding(
                    node: node,
                    pattern: tuplePatternSyntax,
                    typeTuple: binding.typeAnnotation?.type.as(TupleTypeSyntax.self)?.elements,
                    initializerTuple: binding.initializer?.value.as(TupleExprSyntax.self)?.elements)
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

    func visitVariableTupleBinding(node: VariableDeclSyntax, pattern: TuplePatternSyntax, typeTuple: TupleTypeElementListSyntax?, initializerTuple: LabeledExprListSyntax?) {
        let elements = pattern.elements.map { $0 }
        let types: [TupleTypeElementSyntax?] = typeTuple?.map { $0 } ?? Array(repeating: nil, count: elements.count)
        let initializers: [LabeledExprSyntax?] = initializerTuple?.map { $0 } ?? Array(repeating: nil, count: elements.count)

        for (element, (type, initializer)) in zip(elements, zip(types, initializers)) {
            if let elementTuplePattern = element.pattern.as(TuplePatternSyntax.self) {
                let typeTuple = type?.type.as(TupleTypeSyntax.self)?.elements
                let initializerTuple = initializer?.expression.as(TupleExprSyntax.self)?.elements

                visitVariableTupleBinding(
                    node: node,
                    pattern: elementTuplePattern,
                    typeTuple: typeTuple,
                    initializerTuple: initializerTuple)
            } else {
                parse(
                    modifiers: node.modifiers,
                    attributes: node.attributes,
                    trivia: node.leadingTrivia,
                    variableType: type?.type,
                    variableInitFunctionCallExpr: initializer?.expression.as(FunctionCallExprSyntax.self),
                    at: element.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    func visitPost(_ node: TypeAliasDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            genericParameterClause: node.genericParameterClause,
            genericWhereClause: node.genericWhereClause,
            typeInitializerClause: node.initializer,
            at: node.name.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: AssociatedTypeDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            inheritanceClause: node.inheritanceClause,
            genericWhereClause: node.genericWhereClause,
            typeInitializerClause: node.initializer,
            at: node.name.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: OperatorDeclSyntax) {
        parse(
            modifiers: nil,
            attributes: nil,
            trivia: node.leadingTrivia,
            at: node.name.positionAfterSkippingLeadingTrivia
        )
    }

    func visitPost(_ node: PrecedenceGroupDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.name.positionAfterSkippingLeadingTrivia
        )
    }

    func visit(_ node: FunctionCallExprSyntax) {
        if let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
           identifierExpr.baseName.tokenKind == .keyword(.Self) {
            didVisitCapitalSelfFunctionCall = true
        }
    }

    // MARK: - Private

    private func parse(
        modifiers: DeclModifierListSyntax?,
        attributes: AttributeListSyntax?,
        trivia: Trivia?,
        variableType: TypeSyntax? = nil,
        parameterClause: FunctionParameterClauseSyntax? = nil,
        closureParameterClause: ClosureParameterClauseSyntax? = nil,
        enumCaseParameterClause: EnumCaseParameterClauseSyntax? = nil,
        returnClause: ReturnClauseSyntax? = nil,
        inheritanceClause: InheritanceClauseSyntax? = nil,
        genericParameterClause: GenericParameterClauseSyntax? = nil,
        genericWhereClause: GenericWhereClauseSyntax? = nil,
        variableInitFunctionCallExpr: FunctionCallExprSyntax? = nil,
        typeInitializerClause: TypeInitializerClauseSyntax? = nil,
        consumeCapitalSelfFunctionCalls: Bool = false,
        at position: AbsolutePosition
    ) {
        let modifierNames = modifiers?.map { $0.name.text } ?? []
        let accessibility = modifierNames.mapFirst { Accessibility(rawValue: $0) }
        let attributeNames = attributes?.compactMap {
            AttributeSyntax($0)?.attributeName.trimmedDescription ?? AttributeSyntax($0)?.attributeName.firstToken(viewMode: .sourceAccurate)?.text
        } ?? []
        let location = sourceLocationBuilder.location(at: position)

        var didVisitCapitalSelfFunctionCall = false
        if consumeCapitalSelfFunctionCalls {
            didVisitCapitalSelfFunctionCall = self.didVisitCapitalSelfFunctionCall
            self.didVisitCapitalSelfFunctionCall = false
        }

        let returnClauseTypeLocations = typeNameLocations(for: returnClause)
        let parameterClauseTypes = parameterClause?.parameters.map { $0.type } ?? []
        let closureParameterClauseTypes = closureParameterClause?.parameters.compactMap { $0.type } ?? []
        let enumCaseParameterClauseTypes = enumCaseParameterClause?.parameters.map { $0.type } ?? []
        let hasGenericFunctionReturnedMetatypeParameters = hasGenericFunctionReturnedMetatypeParameters(
            genericParameterClause: genericParameterClause,
            parameterClauseTypes: parameterClauseTypes + closureParameterClauseTypes + enumCaseParameterClauseTypes,
            returnClauseTypeLocations: returnClauseTypeLocations)

        let parameterClauseLocations = typeLocations(for: parameterClause)
        let closureParameterClauseLocations = typeLocations(for: closureParameterClause)
        let enumCaseParameterClauseLocations = typeLocations(for: enumCaseParameterClause)
        let allParameterClauseLocations = parameterClauseLocations.union(enumCaseParameterClauseLocations)
            .union(closureParameterClauseLocations)

        results.append((
            location: location,
            accessibility: accessibility,
            modifiers: modifierNames,
            attributes: attributeNames,
            commentCommands: CommentCommand.parseCommands(in: trivia),
            variableType: type(for: variableType),
            variableTypeLocations: typeLocations(for: variableType),
            parameterTypeLocations: allParameterClauseLocations,
            returnTypeLocations: returnClauseTypeLocations.mapSet { $0.location },
            inheritedTypeLocations: typeLocations(for: inheritanceClause),
            genericParameterLocations: typeLocations(for: genericParameterClause),
            genericConformanceRequirementLocations: typeLocations(for: genericWhereClause),
            variableInitFunctionCallLocations: locations(for: variableInitFunctionCallExpr),
            functionCallMetatypeArgumentLocations: functionCallMetatypeArgumentLocations(for: variableInitFunctionCallExpr),
            typeInitializerLocations: typeLocations(for: typeInitializerClause?.value),
            hasCapitalSelfFunctionCall: didVisitCapitalSelfFunctionCall,
            hasGenericFunctionReturnedMetatypeParameters: hasGenericFunctionReturnedMetatypeParameters
        ))
    }

    /// Determines whether the function has generic metatype parameters that are also returned.
    /// For example: `func someFunc<T>(type: T.Type) -> T`.
    private func hasGenericFunctionReturnedMetatypeParameters(
        genericParameterClause: GenericParameterClauseSyntax?,
        parameterClauseTypes: [TypeSyntaxProtocol],
        returnClauseTypeLocations: Set<TypeNameSourceLocation>
    ) -> Bool {
        guard let genericParameterClause else { return false }

        let genericParameterNames = genericParameterClause
            .parameters
            .mapSet { $0.name.trimmedDescription }

        return parameterClauseTypes
            .contains {
                if let baseTypeName = $0.as(MetatypeTypeSyntax.self)?.baseType.trimmedDescription,
                   genericParameterNames.contains(baseTypeName),
                   returnClauseTypeLocations.contains(where: { $0.name == baseTypeName })
                {
                    return true
                }

                return false
            }
    }

    private func type(for typeSyntax: TypeSyntax?) -> String? {
        guard let typeSyntax = typeSyntax else { return nil }
        return typeSyntaxInspector.type(for: typeSyntax)
    }

    private func typeLocations(for typeSyntax: TypeSyntax?) -> Set<Location> {
        guard let typeSyntax = typeSyntax else { return [] }
        return typeSyntaxInspector.typeLocations(for: typeSyntax)
    }

    private func typeLocations(for clause: FunctionParameterClauseSyntax?) -> Set<Location> {
        guard let clause = clause else { return [] }

        return clause.parameters.reduce(into: .init(), { result, param in
            result.formUnion(typeSyntaxInspector.typeLocations(for: param.type))

            if let defaultValue = param.defaultValue?.value {
                result.formUnion(identifierLocations(for: defaultValue))
            }
        })
    }

    private func identifierLocations(for expr: ExprSyntax) -> Set<Location> {
        expr.children(viewMode: .sourceAccurate).flatMapSet { child in
            if let token = child.as(TokenSyntax.self), case .identifier = token.tokenKind {
                return [sourceLocationBuilder.location(at: token.positionAfterSkippingLeadingTrivia)]
            } else if let childExpr = child.as(ExprSyntax.self) {
                return identifierLocations(for: childExpr)
            }

            return []
        }
    }

    private func typeLocations(for clause: ClosureParameterClauseSyntax?) -> Set<Location> {
        guard let clause = clause else { return [] }

        return clause.parameters.reduce(into: .init(), { result, param in
            if let type = param.type {
                result.formUnion(typeSyntaxInspector.typeLocations(for: type))
            }
        })
    }

    private func typeLocations(for clause: EnumCaseParameterClauseSyntax?) -> Set<Location> {
        guard let clause = clause else { return [] }

        return clause.parameters.reduce(into: .init(), { result, param in
            result.formUnion(typeSyntaxInspector.typeLocations(for: param.type))
        })
    }

    private func typeNameLocations(for clause: ReturnClauseSyntax?) -> Set<TypeNameSourceLocation> {
        guard let returnTypeSyntax = clause?.type else { return [] }

        if let someReturnType = returnTypeSyntax.as(SomeOrAnyTypeSyntax.self) {
            return typeSyntaxInspector.typeNameLocations(for: someReturnType.constraint)
        }

        return typeSyntaxInspector.typeNameLocations(for: returnTypeSyntax)
    }

    private func typeLocations(for clause: GenericParameterClauseSyntax?) -> Set<Location> {
        guard let clause = clause else { return [] }

        return clause.parameters.reduce(into: .init()) { result, param in
            if let inheritedType = param.inheritedType {
                result.formUnion(typeSyntaxInspector.typeLocations(for: inheritedType))
            }
        }
    }

    private func typeLocations(for clause: GenericArgumentClauseSyntax?) -> Set<Location> {
        guard let clause = clause else { return [] }

        return clause.arguments.reduce(into: .init()) { result, param in
            result.formUnion(typeSyntaxInspector.typeLocations(for: param.argument))
        }
    }

    private func typeLocations(for clause: GenericWhereClauseSyntax?) -> Set<Location> {
        guard let clause = clause else { return [] }

        return clause.requirements.reduce(into: .init()) { result, requirement in
            if let conformanceRequirementType = requirement.requirement.as(ConformanceRequirementSyntax.self) {
                result.formUnion(typeSyntaxInspector.typeLocations(for: conformanceRequirementType.rightType))
            }
        }
    }

    private func typeLocations(for clause: InheritanceClauseSyntax?) -> Set<Location> {
        guard let clause = clause else { return [] }

        return clause.inheritedTypes.reduce(into: .init()) { result, type in
            result.formUnion(typeSyntaxInspector.typeLocations(for: type.type))
        }
    }

    private func locations(for call: FunctionCallExprSyntax?) -> Set<Location> {
        guard let call = call else { return [] }

        var locations = Set([sourceLocationBuilder.location(at: call.positionAfterSkippingLeadingTrivia)])

        if let expr = call.calledExpression.as(GenericSpecializationExprSyntax.self) {
            locations.formUnion(typeLocations(for: expr.genericArgumentClause))
        }

        return locations
    }

    private func functionCallMetatypeArgumentLocations(for call: FunctionCallExprSyntax?) -> Set<Location> {
        guard let call else { return [] }

        return call
            .arguments
            .reduce(into: .init(), { result, argument in
                if let memberExpr = argument.expression.as(MemberAccessExprSyntax.self),
                   memberExpr.declName.baseName.tokenKind == .keyword(.`self`),
                   let baseIdentifier = memberExpr.base?.as(DeclReferenceExprSyntax.self)
                {
                    let location = sourceLocationBuilder.location(at: baseIdentifier.positionAfterSkippingLeadingTrivia)
                    result.insert(location)
                }
            })
    }
}

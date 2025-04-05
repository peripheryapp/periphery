import Foundation
import Shared
import SourceGraph
import SwiftSyntax

struct TypeNameSourceLocation: Hashable {
    let name: String
    let location: Location
}

struct TypeSyntaxInspector {
    let sourceLocationBuilder: SourceLocationBuilder

    func type(for typeSyntax: TypeSyntax) -> String {
        PropertyTypeSanitizer.sanitize(typeSyntax.description)
    }

    func typeNameLocations(for typeSyntax: TypeSyntax) -> Set<TypeNameSourceLocation> {
        types(for: typeSyntax).mapSet {
            .init(name: $0.trimmedDescription,
                  location: sourceLocationBuilder.location(at: $0.positionAfterSkippingLeadingTrivia))
        }
    }

    func typeLocations(for typeSyntax: TypeSyntax) -> Set<Location> {
        types(for: typeSyntax).mapSet { sourceLocationBuilder.location(at: $0.positionAfterSkippingLeadingTrivia) }
    }

    // MARK: - Private

    func types(for typeSyntax: TypeSyntax) -> Set<TokenSyntax> {
        if let identifierType = typeSyntax.as(IdentifierTypeSyntax.self) {
            // Simple type.
            var result: Set<TokenSyntax> = identifierType.genericArgumentClause?.arguments.flatMapSet {
                guard case let .type(argumentType) = $0.argument else { return [] }
                return types(for: argumentType)
            } ?? []
            return result.inserting(identifierType.name)
        } else if let optionalType = typeSyntax.as(OptionalTypeSyntax.self) {
            // Optional type.
            return types(for: optionalType.wrappedType)
        } else if let memberType = typeSyntax.as(MemberTypeSyntax.self) {
            // Member type.
            return types(for: memberType.baseType)
                .union(memberType.genericArgumentClause?.arguments.flatMapSet {
                    guard case let .type(argumentType) = $0.argument else { return [] }
                    return types(for: argumentType)
                } ?? [])
                .union([memberType.name])
        } else if let tuple = typeSyntax.as(TupleTypeSyntax.self) {
            // Tuple type.
            return tuple.elements.flatMapSet { types(for: $0.type) }
        } else if let funcType = typeSyntax.as(FunctionTypeSyntax.self) {
            // Function type.
            let argumentTypes = funcType.parameters.flatMapSet { types(for: $0.type) }
            return types(for: funcType.returnClause.type).union(argumentTypes)
        } else if let arrayType = typeSyntax.as(ArrayTypeSyntax.self) {
            // Array type.
            return types(for: arrayType.element)
        } else if let dictType = typeSyntax.as(DictionaryTypeSyntax.self) {
            // Dictionary type.
            return types(for: dictType.key).union(types(for: dictType.value))
        } else if let someType = typeSyntax.as(SomeOrAnyTypeSyntax.self) {
            // Some type.
            return types(for: someType.constraint)
        } else if let implicitUnwrappedOptionalType = typeSyntax.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            // Implicitly unwrapped optional type.
            return types(for: implicitUnwrappedOptionalType.wrappedType)
        } else if let compositionType = typeSyntax.as(CompositionTypeSyntax.self) {
            // Composition type.
            return compositionType.elements.flatMapSet { types(for: $0.type) }
        } else if let attributedType = typeSyntax.as(AttributedTypeSyntax.self) {
            // Attributed type.
            return types(for: attributedType.baseType)
        } else if let metatypeType = typeSyntax.as(MetatypeTypeSyntax.self) {
            // Metatype type.
            return types(for: metatypeType.baseType)
        }

        return []
    }
}

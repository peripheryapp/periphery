import Foundation
import SwiftSyntax
import Shared

struct TypeNameSourceLocation: Hashable {
    let name: String
    let location: SourceLocation
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

    func typeLocations(for typeSyntax: TypeSyntax) -> Set<SourceLocation> {
        types(for: typeSyntax).mapSet { sourceLocationBuilder.location(at: $0.positionAfterSkippingLeadingTrivia) }
    }

    // MARK: - Private

    func types(for typeSyntax: TypeSyntax) -> Set<TokenSyntax> {
        if let simpleType = typeSyntax.as(SimpleTypeIdentifierSyntax.self) {
            // Simple type.
            var result = simpleType.genericArgumentClause?.arguments.flatMapSet { types(for: $0.argumentType) } ?? []
            return result.inserting(simpleType.name)
        } else if let optionalType = typeSyntax.as(OptionalTypeSyntax.self) {
            // Optional type.
            return types(for: optionalType.wrappedType)
        } else if let memberType = typeSyntax.as(MemberTypeIdentifierSyntax.self) {
            // Member type.
            return types(for: memberType.baseType).union([memberType.name])
        } else if let tuple = typeSyntax.as(TupleTypeSyntax.self) {
            // Tuple type.
            return tuple.elements.flatMapSet { types(for: $0.type) }
        } else if let funcType = typeSyntax.as(FunctionTypeSyntax.self) {
            // Function type.
            let argumentTypes = funcType.arguments.flatMapSet { types(for: $0.type) }
            return types(for: funcType.output.returnType).union(argumentTypes)
        } else if let arrayType = typeSyntax.as(ArrayTypeSyntax.self) {
            // Array type.
            return types(for: arrayType.elementType)
        } else if let dictType = typeSyntax.as(DictionaryTypeSyntax.self) {
            // Dictionary type.
            return types(for: dictType.keyType).union(types(for: dictType.valueType))
        } else if let someType = typeSyntax.as(ConstrainedSugarTypeSyntax.self) {
            // Some type.
            return types(for: someType.baseType)
        } else if let implicitUnwrappedOptionalType = typeSyntax.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            // Implicitly unwrapped optional type.
            return types(for: implicitUnwrappedOptionalType.wrappedType)
        } else if let compositionType = typeSyntax.as(CompositionTypeSyntax.self) {
            // Composition type.
            return Set(compositionType.elements.flatMap { types(for: $0.type) })
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

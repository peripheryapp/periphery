import Foundation
import SwiftSyntax
import Shared

struct TypeSyntaxInspector {
    let sourceLocationBuilder: SourceLocationBuilder

    func type(for typeSyntax: TypeSyntax) -> String {
        PropertyTypeSanitizer.sanitize(typeSyntax.description)
    }

    func typeLocations(for typeSyntax: TypeSyntax) -> Set<SourceLocation> {
        if let simpleType = typeSyntax.as(SimpleTypeIdentifierSyntax.self) {
            // Simple type.
            let location = nameTypeLocation(for: simpleType.name)
            let genericTypeLocations = Set(simpleType.genericArgumentClause?.arguments.flatMap { typeLocations(for: $0.argumentType) } ?? [])
            return genericTypeLocations.union([location])
        } else if let optionalType = typeSyntax.as(OptionalTypeSyntax.self) {
            // Optional type.
            return typeLocations(for: optionalType.wrappedType)
        } else if let memberType = typeSyntax.as(MemberTypeIdentifierSyntax.self) {
            // Member type
            let location = sourceLocationBuilder.location(at: memberType.name.positionAfterSkippingLeadingTrivia)
            return typeLocations(for: memberType.baseType).union([location])
        } else if let tuple = typeSyntax.as(TupleTypeSyntax.self) {
            // Tuple type.
            return Set(tuple.elements.flatMap { typeLocations(for: $0.type) })
        } else if let funcType = typeSyntax.as(FunctionTypeSyntax.self) {
            // Function type.
            let locations = funcType.arguments.flatMap { typeLocations(for: $0.type) }
            return typeLocations(for: funcType.output.returnType).union(locations)
        } else if let arrayType = typeSyntax.as(ArrayTypeSyntax.self) {
            // Array type.
            return typeLocations(for: arrayType.elementType)
        } else if let dictType = typeSyntax.as(DictionaryTypeSyntax.self) {
            // Dictionary type.
            return typeLocations(for: dictType.keyType).union(typeLocations(for: dictType.valueType))
        } else if let someType = typeSyntax.as(ConstrainedSugarTypeSyntax.self) {
            // Some type.
            return typeLocations(for: someType.baseType)
        } else if let implicitUnwrappedOptionalType = typeSyntax.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            // Implicitly unwrapped optional type.
            return typeLocations(for: implicitUnwrappedOptionalType.wrappedType)
        } else if let compositionType = typeSyntax.as(CompositionTypeSyntax.self) {
            // Composition type.
            return Set(compositionType.elements.flatMap { typeLocations(for: $0.type) })
        } else if let attributedType = typeSyntax.as(AttributedTypeSyntax.self) {
            // Attributed type.
            return typeLocations(for: attributedType.baseType)
        } else if let metatypeType = typeSyntax.as(MetatypeTypeSyntax.self) {
            // Metatype type.
            return typeLocations(for: metatypeType.baseType)
        }

        return [sourceLocationBuilder.location(at: typeSyntax.positionAfterSkippingLeadingTrivia)]
    }

    // MARK: - Private

    private func nameTypeLocation(for name: TokenSyntax) -> SourceLocation {
        sourceLocationBuilder.location(at: name.positionAfterSkippingLeadingTrivia)
    }
}

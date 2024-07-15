import Foundation
import SwiftParser
import SwiftSyntax
import SystemPackage
import SyntaxAnalyse
import SourceGraph

final class RedundantProtocolSyntaxRemover: SyntaxRewriter, SyntaxRemover, TriviaSplitting {
    private let resultLocation: Location
    private let replacements: [String]
    private let locationBuilder: SourceLocationBuilder

    init(resultLocation: Location, replacements: [String], locationBuilder: SourceLocationBuilder) {
        self.resultLocation = resultLocation
        self.replacements = replacements
        self.locationBuilder = locationBuilder
    }

    func perform(syntax: SourceFileSyntax) -> SourceFileSyntax {
        visit(syntax)
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        let node = super.visit(node)
        var didRemoveDeclaration = false

        let newChildren = node.compactMap { child -> CodeBlockItemSyntax? in
            guard let name = child.item.as(ProtocolDeclSyntax.self)?.name else { return child }

            if resultLocation == locationBuilder.location(at: name.positionAfterSkippingLeadingTrivia) {
                didRemoveDeclaration = true
                return remainingTriviaDecl(from: child.item.leadingTrivia)
            }

            return child
        }

        if didRemoveDeclaration {
            return CodeBlockItemListSyntax(newChildren)
        }

        return node
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        guard let node = super.visit(node).as(ClassDeclSyntax.self) else { return DeclSyntax(node) }
        guard let inheritanceClause = node.inheritanceClause else { return DeclSyntax(node) }

        var didRemoveDeclaration = false

        let newInheritedTypes = inheritanceClause.inheritedTypes.filter { type in
            let typeLocation = locationBuilder.location(at: type.type.positionAfterSkippingLeadingTrivia)

            if resultLocation == typeLocation {
                didRemoveDeclaration = true
                return false
            }

            return true
        }

        if didRemoveDeclaration {
            return replacingInheritedTypes(
                node: node,
                inheritanceClause: inheritanceClause,
                newInheritedTypes: newInheritedTypes,
                triviaRecipient: \.name
            )
        }

        return DeclSyntax(node)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        guard let node = super.visit(node).as(StructDeclSyntax.self) else { return DeclSyntax(node) }
        guard let inheritanceClause = node.inheritanceClause else { return DeclSyntax(node) }

        var didRemoveDeclaration = false

        let newInheritedTypes = inheritanceClause.inheritedTypes.filter { type in
            let typeLocation = locationBuilder.location(at: type.type.positionAfterSkippingLeadingTrivia)

            if resultLocation == typeLocation {
                didRemoveDeclaration = true
                return false
            }

            return true
        }

        if didRemoveDeclaration {
            return replacingInheritedTypes(
                node: node,
                inheritanceClause: inheritanceClause,
                newInheritedTypes: newInheritedTypes,
                triviaRecipient: \.name
            )
        }

        return DeclSyntax(node)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        guard let node = super.visit(node).as(EnumDeclSyntax.self) else { return DeclSyntax(node) }
        guard let inheritanceClause = node.inheritanceClause else { return DeclSyntax(node) }

        var didRemoveDeclaration = false

        let newInheritedTypes = inheritanceClause.inheritedTypes.filter { type in
            let typeLocation = locationBuilder.location(at: type.type.positionAfterSkippingLeadingTrivia)

            if resultLocation == typeLocation {
                didRemoveDeclaration = true
                return false
            }

            return true
        }

        if didRemoveDeclaration {
            return replacingInheritedTypes(
                node: node,
                inheritanceClause: inheritanceClause,
                newInheritedTypes: newInheritedTypes,
                triviaRecipient: \.name
            )
        }

        return DeclSyntax(node)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        guard let node = super.visit(node).as(ExtensionDeclSyntax.self) else { return DeclSyntax(node) }
        guard let inheritanceClause = node.inheritanceClause else { return DeclSyntax(node) }

        var didRemoveDeclaration = false

        let newInheritedTypes = inheritanceClause.inheritedTypes.filter { type in
            let typeLocation = locationBuilder.location(at: type.type.positionAfterSkippingLeadingTrivia)

            if resultLocation == typeLocation {
                didRemoveDeclaration = true
                return false
            }

            return true
        }

        if didRemoveDeclaration {
            return replacingInheritedTypes(
                node: node,
                inheritanceClause: inheritanceClause,
                newInheritedTypes: newInheritedTypes,
                triviaRecipient: \.extendedType
            )
        }

        return DeclSyntax(node)
    }

    // MARK: - Private

    private func replacingInheritedTypes<T: TypeDeclWithInheritanceClause, Output: SyntaxProtocol>(
        node: T,
        inheritanceClause: InheritanceClauseSyntax,
        newInheritedTypes: InheritedTypeListSyntax,
        triviaRecipient: WritableKeyPath<T, Output>
    ) -> DeclSyntax {
        var newInheritedTypes = newInheritedTypes

        if !replacements.isEmpty, let last = newInheritedTypes.last {
            // Before appending more types we need to add a comma to the current final item.
            let newLast = last
                .with(\.trailingTrivia, [])
                .with(\.trailingComma, .commaToken(trailingTrivia: .space))
            let endIndex = newInheritedTypes.index(newInheritedTypes.startIndex, offsetBy: newInheritedTypes.count - 1)
            newInheritedTypes[endIndex] = newLast
        }

        for replacement in replacements {
            let inheritedType = InheritedTypeSyntax(
                type: IdentifierTypeSyntax(name: .identifier(replacement)),
                trailingComma: .commaToken(),
                trailingTrivia: .space
            )
            newInheritedTypes.append(inheritedType)
        }

        let newNode: T

        if newInheritedTypes.count > 0 {
            // Remove the trailing coma from the final type
            let endIndex = newInheritedTypes.index(newInheritedTypes.startIndex, offsetBy: newInheritedTypes.count - 1)
            var newType = newInheritedTypes[endIndex]
            let preservedTrivia = newType.trailingTrivia
            newType = newType.with(\.trailingComma, nil)
            newType = newType.with(\.trailingTrivia, preservedTrivia)
            newInheritedTypes[endIndex] = newType

            let newInheritanceClause = inheritanceClause.with(\.inheritedTypes, newInheritedTypes)
            newNode = node.with(\.inheritanceClause, newInheritanceClause)
        } else {
            let triviaRecipientNode = node[keyPath: triviaRecipient]
            let newExtendedType = triviaRecipientNode.with(\.trailingTrivia, triviaRecipientNode.trailingTrivia + inheritanceClause.trailingTrivia)
            newNode = node
                .with(\.inheritanceClause, nil)
                .with(triviaRecipient, newExtendedType)
        }

        return DeclSyntax(newNode)
    }
}

protocol TypeDeclWithInheritanceClause: DeclSyntaxProtocol {
    var inheritanceClause: InheritanceClauseSyntax? { get set }
}
extension ExtensionDeclSyntax: TypeDeclWithInheritanceClause {}
extension ClassDeclSyntax: TypeDeclWithInheritanceClause {}
extension StructDeclSyntax: TypeDeclWithInheritanceClause {}
extension EnumDeclSyntax: TypeDeclWithInheritanceClause {}

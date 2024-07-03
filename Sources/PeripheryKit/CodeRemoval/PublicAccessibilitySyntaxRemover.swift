import Foundation
import SourceGraph
import SwiftParser
import SwiftSyntax
import SystemPackage

final class PublicAccessibilitySyntaxRemover: SyntaxRewriter, SyntaxRemover {
    private let resultLocation: Location
    private let locationBuilder: SourceLocationBuilder

    init(resultLocation: Location, replacements: [String], locationBuilder: SourceLocationBuilder) {
        self.resultLocation = resultLocation
        self.locationBuilder = locationBuilder
    }

    func perform(syntax: SourceFileSyntax) -> SourceFileSyntax {
        visit(syntax)
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.name.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.classKeyword
        )
        return super.visit(newNode)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.name.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.structKeyword
        )
        return super.visit(newNode)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.name.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.enumKeyword
        )
        return super.visit(newNode)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.extendedType.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.extensionKeyword
        )
        return super.visit(newNode)
    }

    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.name.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.protocolKeyword
        )
        return super.visit(newNode)
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.initKeyword.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.initKeyword
        )
        return super.visit(newNode)
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.name.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.funcKeyword
        )
        return super.visit(newNode)
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.subscriptKeyword.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.subscriptKeyword
        )
        return super.visit(newNode)
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.name.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.typealiasKeyword
        )
        return super.visit(newNode)
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.bindings.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.bindingSpecifier
        )
        return super.visit(newNode)
    }

    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.name.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.actorKeyword
        )
        return super.visit(newNode)
    }

    override func visit(_ node: AssociatedTypeDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.name.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.associatedtypeKeyword
        )
        return super.visit(newNode)
    }

    override func visit(_ node: PrecedenceGroupDeclSyntax) -> DeclSyntax {
        let newNode = removePublicModifier(
            from: node,
            at: node.name.positionAfterSkippingLeadingTrivia,
            triviaRecipient: \.precedencegroupKeyword
        )
        return super.visit(newNode)
    }

    // MARK: - Private

    private func removePublicModifier<T: PublicModifiedDecl, Output: SyntaxProtocol>(
        from node: T,
        at position: AbsolutePosition,
        triviaRecipient: WritableKeyPath<T, Output>
    ) -> T {
        var removedLeadingTrivia = Trivia(pieces: [])
        var didRemove = false

        var newModifiers = node.modifiers.filter { modifier in
            if locationBuilder.location(at: position) == resultLocation,
               modifier.name.text == "public" {
                didRemove = true
                removedLeadingTrivia = modifier.leadingTrivia
                return false
            }

            return true
        }

        var newNode = node

        if didRemove {
            if newModifiers.count == 0 {
                let triviaRecipientNode = node[keyPath: triviaRecipient]
                let newTriviaRecipientNode = triviaRecipientNode
                    .with(\.leadingTrivia, removedLeadingTrivia + newModifiers.leadingTrivia)
                newNode = newNode.with(triviaRecipient, newTriviaRecipientNode)
            } else {
                newModifiers = newModifiers
                    .with(\.leadingTrivia, removedLeadingTrivia + newModifiers.leadingTrivia)
            }

            return newNode.with(\.modifiers, newModifiers)
        } else {
            return node
        }
    }
}

protocol PublicModifiedDecl: SyntaxProtocol {
    var modifiers: DeclModifierListSyntax { get set }
}

extension ClassDeclSyntax: PublicModifiedDecl {}
extension StructDeclSyntax: PublicModifiedDecl {}
extension EnumDeclSyntax: PublicModifiedDecl {}
extension EnumCaseDeclSyntax: PublicModifiedDecl {}
extension ExtensionDeclSyntax: PublicModifiedDecl {}
extension ProtocolDeclSyntax: PublicModifiedDecl {}
extension InitializerDeclSyntax: PublicModifiedDecl {}
extension FunctionDeclSyntax: PublicModifiedDecl {}
extension SubscriptDeclSyntax: PublicModifiedDecl {}
extension TypeAliasDeclSyntax: PublicModifiedDecl {}
extension VariableDeclSyntax: PublicModifiedDecl {}
extension ActorDeclSyntax: PublicModifiedDecl {}
extension AssociatedTypeDeclSyntax: PublicModifiedDecl {}
extension PrecedenceGroupDeclSyntax: PublicModifiedDecl {}

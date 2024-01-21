import Foundation
import SwiftParser
import SwiftSyntax
import SystemPackage

final class UnusedDeclarationSyntaxRemover: SyntaxRewriter, SyntaxRemover, TriviaSplitting {
    private let resultLocation: SourceLocation
    private let locationBuilder: SourceLocationBuilder

    init(resultLocation: SourceLocation, replacements: [String], locationBuilder: SourceLocationBuilder) {
        self.resultLocation = resultLocation
        self.locationBuilder = locationBuilder
    }

    func perform(syntax: SourceFileSyntax) -> SourceFileSyntax {
        visit(syntax)
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        let node = super.visit(node)
        var didRemoveDeclaration = false

        let newChildren = node.compactMap { child -> CodeBlockItemSyntax? in
            if hasRemovableChild(from: child.item) {
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

    override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
        let node = super.visit(node)
        var didRemoveDeclaration = false

        let newMembers = node.compactMap { member -> MemberBlockItemSyntax? in
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                guard varDecl.bindings.count == 1, // TODO: Handle multiple bindings,
                      let binding = varDecl.bindings.first
                else { return member }

                let patternLocation = locationBuilder.location(at: binding.pattern.positionAfterSkippingLeadingTrivia)
                if resultLocation == patternLocation {
                    didRemoveDeclaration = true
                    return remainingTriviaDecl(from: varDecl.leadingTrivia)
                }

                return member
            } else if let subscriptDecl = member.decl.as(SubscriptDeclSyntax.self) {
                let patternLocation = locationBuilder.location(at: subscriptDecl.subscriptKeyword.positionAfterSkippingLeadingTrivia)
                if resultLocation == patternLocation {
                    didRemoveDeclaration = true
                    return remainingTriviaDecl(from: subscriptDecl.leadingTrivia)
                }

                return member
            } else if let enumDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                let indexToRemove = enumDecl.elements.firstIndex { element in
                    locationBuilder.location(at: element.positionAfterSkippingLeadingTrivia) == resultLocation
                }

                guard let indexToRemove else { return member }

                didRemoveDeclaration = true

                var newElements = enumDecl.elements

                newElements.remove(at: indexToRemove)

                if newElements.count == 0 {
                    return remainingTriviaDecl(from: enumDecl.leadingTrivia)
                }

                // Remove the trailing coma from the final element
                let endIndex = newElements.index(newElements.startIndex, offsetBy: newElements.count - 1)
                newElements[endIndex] = newElements[endIndex].with(\.trailingComma, nil)

                let newEnumDecl = enumDecl.with(\.elements, newElements)
                return member.with(\.decl, DeclSyntax(newEnumDecl))
            } else if hasRemovableChild(from: member.decl) {
                didRemoveDeclaration = true
                return remainingTriviaDecl(from: member.decl.leadingTrivia)
            }

            return member
        }

        if didRemoveDeclaration {
            return MemberBlockItemListSyntax(newMembers)
        }

        return node
    }

    // MARK: - Private

    private func hasRemovableChild(from node: SyntaxProtocol) -> Bool {
        return node.children(viewMode: .sourceAccurate).contains { child in
            var position: AbsolutePosition?

            if let initDecl = child.as(InitializerDeclSyntax.self) {
                position = initDecl.initKeyword.positionAfterSkippingLeadingTrivia
            } else if let identifier = child.as(IdentifierTypeSyntax.self) {
                position = identifier.name.positionAfterSkippingLeadingTrivia
            } else if let member = child.as(MemberTypeSyntax.self) {
                return hasRemovableChild(from: member)
            } else if let token = child.as(TokenSyntax.self) {
                if token.tokenKind.isRemovableKind {
                    position = token.positionAfterSkippingLeadingTrivia
                }
            }

            guard let position else { return false }

            if resultLocation == locationBuilder.location(at: position) {
                return true
            }

            return false
        }
    }
}

extension TokenKind {
    var isRemovableKind: Bool {
        switch self {
        case .identifier, .binaryOperator, .prefixOperator, .postfixOperator:
            return true
        case .keyword(let keyword) where keyword == .`init`:
            return true
        default:
            return false
        }
    }
}

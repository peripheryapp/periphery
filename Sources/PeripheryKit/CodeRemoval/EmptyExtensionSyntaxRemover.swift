import Foundation
import Foundation
import SwiftParser
import SwiftSyntax
import SystemPackage

final class EmptyExtensionSyntaxRemover: SyntaxRewriter, TriviaSplitting {
    func perform(syntax: SourceFileSyntax) -> SourceFileSyntax {
        visit(syntax)
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        let newChildren = node.compactMap { child -> CodeBlockItemSyntax? in
            guard let extDecl = child.item.as(ExtensionDeclSyntax.self) else { return child }

            let members = extDecl.memberBlock.members
            let hasMembers = !(members.count == 0 || (members.count == 1 && members.first?.decl.is(MissingDeclSyntax.self) ?? false))
            let hasInheritance = extDecl.inheritanceClause != nil

            if !hasMembers, !hasInheritance {
                return remainingTriviaDecl(from: child.item.leadingTrivia)
            }

            return child
        }

        return CodeBlockItemListSyntax(newChildren)
    }
}

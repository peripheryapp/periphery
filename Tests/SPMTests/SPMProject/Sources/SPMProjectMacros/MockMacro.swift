import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftOperators

struct MockMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else { return [] }

        let protocolName = protocolDecl.name.text
        let mockName = "\(protocolName)Mock"

        let mockClass = DeclSyntax(
            ClassDeclSyntax(
                modifiers: [DeclModifierSyntax(name: "public")],
                name: .identifier(mockName),
                inheritanceClause: InheritanceClauseSyntax {
                    InheritedTypeSyntax(type: TypeSyntax(stringLiteral: protocolName))
                },
                memberBlock: MemberBlockSyntax {}
            )
        )

        return [mockClass]
    }
}

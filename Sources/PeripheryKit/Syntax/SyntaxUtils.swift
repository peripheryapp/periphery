import Foundation
import SwiftSyntax

struct SyntaxUtils {
    static func correctPosition(of syntax: InitializerDeclSyntax) -> AbsolutePosition {
        // syntax.initKeyword.position is incorrect, try to find the correct position.
        var position = syntax.initKeyword.position

        if let leftBracket = syntax.genericParameterClause?.leftAngleBracket {
            position = AbsolutePosition(utf8Offset: leftBracket.position.utf8Offset - 4)
        } else if syntax.optionalMark != nil {
            let leftParen = syntax.parameters.leftParen
            position = AbsolutePosition(utf8Offset: leftParen.position.utf8Offset - 5)
        } else {
            let leftParen = syntax.parameters.leftParen
            position = AbsolutePosition(utf8Offset: leftParen.position.utf8Offset - 4)
        }

        return position
    }
}

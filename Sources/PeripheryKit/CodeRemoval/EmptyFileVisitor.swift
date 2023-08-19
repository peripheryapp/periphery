import Foundation
import Foundation
import SwiftParser
import SwiftSyntax
import SystemPackage

final class EmptyFileVisitor: SyntaxVisitor, TriviaSplitting {
    private var isEmpty = false

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    func perform(syntax: SourceFileSyntax) -> Bool {
        walk(syntax)
        return isEmpty
    }

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        if node.statements.count == 0 {
            isEmpty = true
        } else {
            isEmpty = node.statements.allSatisfy {
                $0.item.is(ImportDeclSyntax.self) || $0.item.is(MissingDeclSyntax.self)
            }
        }

        return .skipChildren
    }
}

import Foundation
import SwiftParser
import SwiftSyntax

protocol TriviaSplitting {
    func remainingTriviaDecl<T: TriviaInitializedItem>(from trivia: Trivia) -> T?
}

protocol TriviaInitializedItem {
    init(triviaDecl: DeclSyntax)
}

extension TriviaSplitting {
    func remainingTriviaDecl<T: TriviaInitializedItem>(from trivia: Trivia) -> T? {
        let lines = trivia.description.split(separator: "\n", omittingEmptySubsequences: false)
            .reversed()
            .dropFirst() // Drop the newline that all trivia ends with

        let blankLineIdx = lines.firstIndex { line in
            line.trimmingCharacters(in: .whitespaces).isEmpty
        }

        guard let blankLineIdx else { return nil }

        let remainingLines = lines[blankLineIdx..<lines.endIndex]
            .reversed()
            .joined(separator: "\n")
        let triviaDecl = MissingDeclSyntax(placeholder: .stringSegment(remainingLines))
        return T.init(triviaDecl: DeclSyntax(triviaDecl))
    }
}

extension CodeBlockItemSyntax: TriviaInitializedItem {
    init(triviaDecl: DeclSyntax) {
        self.init(item: .decl(triviaDecl))
    }
}

extension MemberBlockItemSyntax: TriviaInitializedItem {
    init(triviaDecl: DeclSyntax) {
        self.init(decl: triviaDecl)
    }
}

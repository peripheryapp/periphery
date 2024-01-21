import SwiftSyntax

protocol SyntaxRemover {
    init(resultLocation: SourceLocation, replacements: [String], locationBuilder: SourceLocationBuilder)
    func perform(syntax: SourceFileSyntax) -> SourceFileSyntax
}

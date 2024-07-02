import SwiftSyntax
import SourceGraph

protocol SyntaxRemover {
    init(resultLocation: Location, replacements: [String], locationBuilder: SourceLocationBuilder)
    func perform(syntax: SourceFileSyntax) -> SourceFileSyntax
}

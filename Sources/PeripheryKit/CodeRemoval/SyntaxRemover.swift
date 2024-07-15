import SwiftSyntax
import SourceGraph
import SyntaxAnalyse

protocol SyntaxRemover {
    init(resultLocation: Location, replacements: [String], locationBuilder: SourceLocationBuilder)
    func perform(syntax: SourceFileSyntax) -> SourceFileSyntax
}

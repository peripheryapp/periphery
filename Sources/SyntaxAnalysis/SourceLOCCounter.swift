import Foundation
import SwiftSyntax

public enum SourceLOCCounter {
    public static func countLines(of syntax: SourceFileSyntax, using locationConverter: SourceLocationConverter) -> Int {
        var lines = IndexSet()

        for token in syntax.tokens(viewMode: .sourceAccurate) {
            guard token.tokenKind != .endOfFile else { continue }

            let start = locationConverter.location(for: token.positionAfterSkippingLeadingTrivia)
            let end = locationConverter.location(for: token.endPositionBeforeTrailingTrivia)

            guard start.line <= end.line else { continue }

            lines.insert(integersIn: start.line ... end.line)
        }

        return lines.count
    }
}

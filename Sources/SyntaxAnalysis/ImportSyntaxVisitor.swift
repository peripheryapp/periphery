import Foundation
import SourceGraph
import SwiftSyntax

public final class ImportSyntaxVisitor: PeripherySyntaxVisitor {
    public var importStatements: [ImportStatement] = []

    private let sourceLocationBuilder: SourceLocationBuilder

    public init(sourceLocationBuilder: SourceLocationBuilder) {
        self.sourceLocationBuilder = sourceLocationBuilder
    }

    public func visit(_ node: ImportDeclSyntax) {
        let parts = node.path.map(\.name.text)
        let module = parts.first ?? ""
        let attributes = node.attributes.compactMap {
            if case let .attribute(attr) = $0 {
                attr.attributeName.trimmedDescription
            } else {
                nil
            }
        }
        let location = sourceLocationBuilder.location(at: node.positionAfterSkippingLeadingTrivia)
        let statement = ImportStatement(
            module: module,
            isTestable: attributes.contains("testable"),
            isExported: attributes.contains("_exported") || node.modifiers.contains { $0.name.text == "public" },
            location: location,
            commentCommands: CommentCommand.parseCommands(in: node.leadingTrivia.merging(node.trailingTrivia))
        )
        importStatements.append(statement)
    }
}

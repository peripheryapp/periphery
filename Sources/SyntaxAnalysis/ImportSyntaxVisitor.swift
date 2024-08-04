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
        let parts = node.path.map { $0.name.text }
        let module = parts.first ?? ""
        let attributes = node.attributes.compactMap { $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription }
        let location = sourceLocationBuilder.location(at: node.positionAfterSkippingLeadingTrivia)
        let statement = ImportStatement(
            module: module,
            isTestable: attributes.contains("testable"),
            isExported: attributes.contains("_exported"),
            location: location)
        importStatements.append(statement)
    }
}

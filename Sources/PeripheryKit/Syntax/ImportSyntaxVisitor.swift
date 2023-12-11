import Foundation
import SwiftSyntax

struct ImportStatement {
    let module: String
    let isTestable: Bool
    let isExported: Bool
    let location: SourceLocation
}

final class ImportSyntaxVisitor: PeripherySyntaxVisitor {
    var importStatements: [ImportStatement] = []

    private let sourceLocationBuilder: SourceLocationBuilder

    init(sourceLocationBuilder: SourceLocationBuilder) {
        self.sourceLocationBuilder = sourceLocationBuilder
    }

    func visit(_ node: ImportDeclSyntax) {
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

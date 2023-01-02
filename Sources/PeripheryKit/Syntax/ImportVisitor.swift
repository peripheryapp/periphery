import Foundation
import SwiftSyntax

final class ImportVisitor: PeripherySyntaxVisitor {
    typealias ImportStatement = (parts: [String], isTestable: Bool)

    var importStatements: [ImportStatement] = []

    init(sourceLocationBuilder: SourceLocationBuilder) {}

    func visit(_ node: ImportDeclSyntax) {
        let parts = node.path.map { $0.name.text }
        let attributes = node.attributes?.compactMap { $0.as(AttributeSyntax.self)?.attributeName.text } ?? []
        importStatements.append((parts, attributes.contains("testable")))
    }
}

import Foundation
import SwiftSyntax
import PathKit
import Shared

final class PropertyTypeParser: SyntaxVisitor {
    static func parse(_ properties: Set<Declaration>) throws -> [String: Set<Declaration>] {
        let typesByLocation = try properties
            .reduce(into: [Path: Set<Declaration>]()) { (result, property) in
                result[property.location.file, default: []].insert(property)
            }
            .reduce(into: [SourceLocation: String]()) { (result, kv) in
                let (file, properties) = kv
                let propertyNamesByLocation = properties
                    .reduce(into: [SourceLocation: String]()) { (result, decl) in
                        if let name = decl.name {
                            result[decl.location] = name
                        }
                    }
                let typesByLocation = try self.init(file: file, propertyNamesByLocation: propertyNamesByLocation).parse()
                result.merge(typesByLocation)  { (_, new) in new }
            }

        return properties.reduce(into: [String: Set<Declaration>]()) { (result, property) in
                if let type = typesByLocation[property.location] {
                    result[type, default: []].insert(property)
                }
            }
    }

    private let file: Path
    private let syntax: SourceFileSyntax
    private let locationConverter: SourceLocationConverter
    private let propertyNamesByLocation: [SourceLocation: String]
    private var typesByLocation: [SourceLocation: String] = [:]

    required init(file: Path, propertyNamesByLocation: [SourceLocation: String]) throws {
        self.file = file
        self.syntax = try SyntaxParser.parse(file.url)
        self.locationConverter = SourceLocationConverter(file: file.string, tree: syntax)
        self.propertyNamesByLocation = propertyNamesByLocation
    }

    func parse() -> [SourceLocation: String] {
        walk(syntax)
        return typesByLocation
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let nodeLocation = sourceLocation(of: node.bindings.position)
        let rawTypeName = node.bindings.map({ $0.typeAnnotation?.type.description ?? "" }).first
        let identifier = node.bindings.map({ $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text ?? "" }).first

        if propertyNamesByLocation[nodeLocation] == identifier, let rawTypeName = rawTypeName {
            let typeName = PropertyTypeSanitizer.sanitize(rawTypeName)
            typesByLocation[nodeLocation] = typeName
        }

        return .skipChildren
    }

    // MARK: - Private

    private func sourceLocation(of position: AbsolutePosition) -> SourceLocation {
        let location = locationConverter.location(for: position)
        return SourceLocation(file: file,
                              line: Int64(location.line ?? 0),
                              column: Int64(location.column ?? 0))
    }
}

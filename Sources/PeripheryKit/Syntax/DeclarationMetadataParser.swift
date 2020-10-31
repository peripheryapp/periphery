import Foundation
import PathKit
import SwiftSyntax

class DeclarationMetadataParser: SyntaxVisitor {
    typealias ModifierSpecifier = (location: SourceLocation, accessibility: Accessibility?, attributes: [String], modifiers: [String])

    private let file: Path
    private let syntax: SourceFileSyntax
    private let locationConverter: SourceLocationConverter

    private var specifiers: [ModifierSpecifier] = []

    static func parse(
        file: Path,
        syntax: SourceFileSyntax,
        locationConverter: SourceLocationConverter
    ) throws -> [ModifierSpecifier] {
        let parser = self.init(
            file: file,
            syntax: syntax,
            locationConverter: locationConverter)
        return try parser.parse()
    }

    internal required init(file: Path, syntax: SourceFileSyntax, locationConverter: SourceLocationConverter) {
        self.file = file
        self.syntax = syntax
        self.locationConverter = locationConverter
    }

    func parse() throws -> [ModifierSpecifier] {
        walk(syntax)
        return specifiers
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: node.identifier.position)
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: node.identifier.position)
        return .skipChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: node.identifier.position)
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: node.identifier.position)
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        var position = node.extendedType.position

        if let memberType = node.extendedType.as(MemberTypeIdentifierSyntax.self) {
            position = memberType.name.position
        }

        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: position)
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: node.identifier.position)
        return .skipChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: SyntaxUtils.correctPosition(of: node))
        return .skipChildren
    }

    override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: node.deinitKeyword.position)
        return .skipChildren
    }

    override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: node.subscriptKeyword.position)
        return .skipChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: node.bindings.position)
        return .skipChildren
    }

    override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: node.identifier.position)
        return .skipChildren
    }

    override func visit(_ node: AssociatedtypeDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: node.identifier.position)
        return .skipChildren
    }

    override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: node.identifier.position)
        return .skipChildren
    }

    override func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
        appendSpecifier(modifiers: node.modifiers, attributes: node.attributes, at: node.identifier.position)
        return .skipChildren
    }

    // MARK: - Private

    private func appendSpecifier(modifiers: ModifierListSyntax?, attributes: AttributeListSyntax?, at position: AbsolutePosition) {
        let modifierNames = modifiers?.map { $0.name.text } ?? []
        let accessibility = modifierNames.mapFirst { Accessibility(rawValue: $0) }
        let attributeNames = attributes?.compactMap { AttributeSyntax($0)?.attributeName.text } ?? []

        if accessibility != nil || !modifierNames.isEmpty || !attributeNames.isEmpty {
            let location = sourceLocation(of: position)
            specifiers.append((location, accessibility, attributeNames, modifierNames))
        }
    }

    private func sourceLocation(of position: AbsolutePosition) -> SourceLocation {
        let location = locationConverter.location(for: position)
        return SourceLocation(file: file,
                              line: Int64(location.line!),
                              column: Int64(location.column!),
                              offset: Int64(position.utf8Offset))
    }
}

import Foundation
import PathKit
import SwiftSyntax

class MetadataParser: SyntaxVisitor {
    typealias Metadata = (
        location: SourceLocation,
        accessibility: Accessibility?,
        attributes: [String],
        modifiers: [String],
        commentCommands: [CommentCommand]
    )
    typealias Result = (fileCommands: [CommentCommand], metadata: [Metadata])

    private let file: Path
    private let syntax: SourceFileSyntax
    private let locationConverter: SourceLocationConverter

    private var locations: [Metadata] = []

    static func parse(
        file: Path,
        syntax: SourceFileSyntax,
        locationConverter: SourceLocationConverter
    ) throws -> Result {
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

    func parse() throws -> Result {
        walk(syntax)
        let fileCommands = parseCommands(in: syntax.leadingTrivia)
        return (fileCommands, locations)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        var position = node.extendedType.position

        if let memberType = node.extendedType.as(MemberTypeIdentifierSyntax.self) {
            position = memberType.name.position
        }

        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: position
        )
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
        return .skipChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: SyntaxUtils.correctPosition(of: node)
        )
        return .skipChildren
    }

    override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.deinitKeyword.position
        )
        return .skipChildren
    }

    override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.subscriptKeyword.position
        )
        return .skipChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.bindings.position
        )
        return .skipChildren
    }

    override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
        return .skipChildren
    }

    override func visit(_ node: AssociatedtypeDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
        return .skipChildren
    }

    override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
        return .skipChildren
    }

    override func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
        return .skipChildren
    }

    // MARK: - Private

    private func parse(
        modifiers: ModifierListSyntax?,
        attributes: AttributeListSyntax?,
        trivia: Trivia?,
        at position: AbsolutePosition
    ) {
        let modifierNames = modifiers?.map { $0.name.text } ?? []
        let accessibility = modifierNames.mapFirst { Accessibility(rawValue: $0) }
        let attributeNames = attributes?.compactMap { AttributeSyntax($0)?.attributeName.text } ?? []
        let commands = parseCommands(in: trivia)

        if accessibility != nil || !modifierNames.isEmpty || !attributeNames.isEmpty || !commands.isEmpty {
            let location = sourceLocation(of: position)
            locations.append((location, accessibility, attributeNames, modifierNames, commands))
        }
    }

    private func parseCommands(in trivia: Trivia?) -> [CommentCommand] {
        let comments: [String] = trivia?.compactMap {
            switch $0 {
            case let .lineComment(comment),
                 let .blockComment(comment),
                 let .docLineComment(comment),
                 let .docBlockComment(comment):
                return comment
            default:
                return nil
            }
        } ?? []

        return comments
            .compactMap { comment in
                guard let range = comment.range(of: "periphery:") else { return nil }
                let rawCommand = String(comment[range.upperBound...]).replacingOccurrences(of: "*/", with: "").trimmed
                return CommentCommand.parse(rawCommand)
            }
    }

    private func sourceLocation(of position: AbsolutePosition) -> SourceLocation {
        let location = locationConverter.location(for: position)
        return SourceLocation(file: file,
                              line: Int64(location.line ?? 0),
                              column: Int64(location.column ?? 0))
    }
}

import Foundation
import PathKit
import SwiftSyntax

final class DeclarationMetadataVisitor: PeripherySyntaxVisitor {
    typealias Result = (
        location: SourceLocation,
        accessibility: Accessibility?,
        attributes: [String],
        modifiers: [String],
        commentCommands: [CommentCommand]
    )

    let file: Path
    let locationConverter: SourceLocationConverter
    private(set) var results: [Result] = []

    required init(file: Path, locationConverter: SourceLocationConverter) {
        self.file = file
        self.locationConverter = locationConverter
    }

    func visit(_ node: ClassDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
    }

    func visit(_ node: ProtocolDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
    }

    func visit(_ node: StructDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
    }

    func visit(_ node: EnumDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
    }

    func visit(_ node: ExtensionDeclSyntax) {
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
    }

    func visit(_ node: FunctionDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
    }

    func visit(_ node: InitializerDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: SyntaxUtils.correctPosition(of: node)
        )
    }

    func visit(_ node: DeinitializerDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.deinitKeyword.position
        )
    }

    func visit(_ node: SubscriptDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.subscriptKeyword.position
        )
    }

    func visit(_ node: VariableDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.bindings.position
        )
    }

    func visit(_ node: TypealiasDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
    }

    func visit(_ node: AssociatedtypeDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
    }

    func visit(_ node: OperatorDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
    }

    func visit(_ node: PrecedenceGroupDeclSyntax) {
        parse(
            modifiers: node.modifiers,
            attributes: node.attributes,
            trivia: node.leadingTrivia,
            at: node.identifier.position
        )
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
        let commands = CommentCommand.parseCommands(in: trivia)

        if accessibility != nil ||
            !modifierNames.isEmpty ||
            !attributeNames.isEmpty ||
            !commands.isEmpty {
            let location = sourceLocation(of: position)
            results.append((location, accessibility, attributeNames, modifierNames, commands))
        }
    }
}

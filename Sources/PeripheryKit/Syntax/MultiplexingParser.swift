import Foundation
import PathKit
import SwiftSyntax

protocol PeripherySyntaxVisitor {
    var file: Path { get }
    var locationConverter: SourceLocationConverter { get }

    init(file: Path, locationConverter: SourceLocationConverter)
    func sourceLocation(of position: AbsolutePosition) -> SourceLocation

    func visit(_ node: ClassDeclSyntax)
    func visit(_ node: ProtocolDeclSyntax)
    func visit(_ node: StructDeclSyntax)
    func visit(_ node: EnumDeclSyntax)
    func visit(_ node: ExtensionDeclSyntax)
    func visit(_ node: FunctionDeclSyntax)
    func visit(_ node: InitializerDeclSyntax)
    func visit(_ node: DeinitializerDeclSyntax)
    func visit(_ node: SubscriptDeclSyntax)
    func visit(_ node: VariableDeclSyntax)
    func visit(_ node: TypealiasDeclSyntax)
    func visit(_ node: AssociatedtypeDeclSyntax)
    func visit(_ node: OperatorDeclSyntax)
    func visit(_ node: PrecedenceGroupDeclSyntax)
}

extension PeripherySyntaxVisitor {
    func sourceLocation(of position: AbsolutePosition) -> SourceLocation {
        let location = locationConverter.location(for: position)
        return SourceLocation(file: file,
                              line: Int64(location.line ?? 0),
                              column: Int64(location.column ?? 0))
    }

    func visit(_ node: ClassDeclSyntax) { }
    func visit(_ node: ProtocolDeclSyntax) { }
    func visit(_ node: StructDeclSyntax) { }
    func visit(_ node: EnumDeclSyntax) { }
    func visit(_ node: ExtensionDeclSyntax) { }
    func visit(_ node: FunctionDeclSyntax) { }
    func visit(_ node: InitializerDeclSyntax) { }
    func visit(_ node: DeinitializerDeclSyntax) { }
    func visit(_ node: SubscriptDeclSyntax) { }
    func visit(_ node: VariableDeclSyntax) { }
    func visit(_ node: TypealiasDeclSyntax) { }
    func visit(_ node: AssociatedtypeDeclSyntax) { }
    func visit(_ node: OperatorDeclSyntax) { }
    func visit(_ node: PrecedenceGroupDeclSyntax) { }
}

final class MultiplexingParser: SyntaxVisitor {
    let file: Path
    let syntax: SourceFileSyntax
    let locationConverter: SourceLocationConverter

    private var visitors: [PeripherySyntaxVisitor] = []

    required init(file: Path) throws {
        self.file = file
        self.syntax = try SyntaxParser.parse(file.url)
        self.locationConverter = SourceLocationConverter(file: file.string, tree: syntax)
    }

    func add<T: PeripherySyntaxVisitor>(_ visitorType: T.Type) -> T {
        let visitor = visitorType.init(file: file, locationConverter: locationConverter)
        visitors.append(visitor)
        return visitor
    }

    func parse() {
        walk(syntax)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: AssociatedtypeDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }
}

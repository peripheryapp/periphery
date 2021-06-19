import Foundation
import SystemPackage
import SwiftSyntax

protocol PeripherySyntaxVisitor {
    static func make(sourceLocationBuilder: SourceLocationBuilder) -> Self

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
    func visit(_ node: ImportDeclSyntax)
}

extension PeripherySyntaxVisitor {
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
    func visit(_ node: ImportDeclSyntax) { }
}

final class MultiplexingSyntaxVisitor: SyntaxVisitor {
    let syntax: SourceFileSyntax
    let locationConverter: SourceLocationConverter
    let sourceLocationBuilder: SourceLocationBuilder

    private var visitors: [PeripherySyntaxVisitor] = []

    required init(file: SourceFile) throws {
        self.syntax = try SyntaxParser.parse(file.path.url)
        self.locationConverter = SourceLocationConverter(file: file.path.string, tree: syntax)
        self.sourceLocationBuilder = SourceLocationBuilder(file: file, locationConverter: locationConverter)
    }

    func add<T: PeripherySyntaxVisitor>(_ visitorType: T.Type) -> T {
        let visitor = visitorType.make(sourceLocationBuilder: sourceLocationBuilder)
        visitors.append(visitor)
        return visitor
    }

    func visit() {
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

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }
}

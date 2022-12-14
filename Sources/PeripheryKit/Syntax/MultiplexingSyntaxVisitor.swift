import Foundation
import SystemPackage
import SwiftSyntax
#if canImport(SwiftSyntaxParser)
import SwiftSyntaxParser
#endif

protocol PeripherySyntaxVisitor {
    static func make(sourceLocationBuilder: SourceLocationBuilder) -> Self

    func visit(_ node: ClassDeclSyntax)
    func visit(_ node: ProtocolDeclSyntax)
    func visit(_ node: StructDeclSyntax)
    func visit(_ node: EnumDeclSyntax)
    func visit(_ node: EnumCaseDeclSyntax)
    func visit(_ node: ExtensionDeclSyntax)
    func visit(_: FunctionDeclSyntax)
    func visit(_ node: InitializerDeclSyntax)
    func visit(_ node: DeinitializerDeclSyntax)
    func visit(_ node: SubscriptDeclSyntax)
    func visit(_ node: VariableDeclSyntax)
    func visit(_ node: TypealiasDeclSyntax)
    func visit(_ node: AssociatedtypeDeclSyntax)
    func visit(_ node: OperatorDeclSyntax)
    func visit(_ node: PrecedenceGroupDeclSyntax)
    func visit(_ node: ImportDeclSyntax)
    func visit(_ node: OptionalBindingConditionSyntax)

    func visitPost(_ node: ClassDeclSyntax)
    func visitPost(_ node: ProtocolDeclSyntax)
    func visitPost(_ node: StructDeclSyntax)
    func visitPost(_ node: EnumDeclSyntax)
    func visitPost(_ node: EnumCaseDeclSyntax)
    func visitPost(_ node: ExtensionDeclSyntax)
    func visitPost(_ node: FunctionDeclSyntax)
    func visitPost(_ node: InitializerDeclSyntax)
    func visitPost(_ node: DeinitializerDeclSyntax)
    func visitPost(_ node: SubscriptDeclSyntax)
    func visitPost(_ node: VariableDeclSyntax)
    func visitPost(_ node: TypealiasDeclSyntax)
    func visitPost(_ node: AssociatedtypeDeclSyntax)
    func visitPost(_ node: OperatorDeclSyntax)
    func visitPost(_ node: PrecedenceGroupDeclSyntax)
    func visitPost(_ node: ImportDeclSyntax)
    func visitPost(_ node: OptionalBindingConditionSyntax)
}

extension PeripherySyntaxVisitor {
    func visit(_ node: ClassDeclSyntax) { }
    func visit(_ node: ProtocolDeclSyntax) { }
    func visit(_ node: StructDeclSyntax) { }
    func visit(_ node: EnumDeclSyntax) { }
    func visit(_ node: EnumCaseDeclSyntax) { }
    func visit(_ node: ExtensionDeclSyntax) { }
    func visit(_: FunctionDeclSyntax) { }
    func visit(_ node: InitializerDeclSyntax) { }
    func visit(_ node: DeinitializerDeclSyntax) { }
    func visit(_ node: SubscriptDeclSyntax) { }
    func visit(_ node: VariableDeclSyntax) { }
    func visit(_ node: TypealiasDeclSyntax) { }
    func visit(_ node: AssociatedtypeDeclSyntax) { }
    func visit(_ node: OperatorDeclSyntax) { }
    func visit(_ node: PrecedenceGroupDeclSyntax) { }
    func visit(_ node: ImportDeclSyntax) { }
    func visit(_ node: OptionalBindingConditionSyntax) {}

    func visitPost(_ node: ClassDeclSyntax) {}
    func visitPost(_ node: ProtocolDeclSyntax) {}
    func visitPost(_ node: StructDeclSyntax) {}
    func visitPost(_ node: EnumDeclSyntax) {}
    func visitPost(_ node: EnumCaseDeclSyntax) {}
    func visitPost(_ node: ExtensionDeclSyntax) {}
    func visitPost(_ node: FunctionDeclSyntax) {}
    func visitPost(_ node: InitializerDeclSyntax) {}
    func visitPost(_ node: DeinitializerDeclSyntax) {}
    func visitPost(_ node: SubscriptDeclSyntax) {}
    func visitPost(_ node: VariableDeclSyntax) {}
    func visitPost(_ node: TypealiasDeclSyntax) {}
    func visitPost(_ node: AssociatedtypeDeclSyntax) {}
    func visitPost(_ node: OperatorDeclSyntax) {}
    func visitPost(_ node: PrecedenceGroupDeclSyntax) {}
    func visitPost(_ node: ImportDeclSyntax) {}
    func visitPost(_ node: OptionalBindingConditionSyntax) {}
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
        super.init(viewMode: .sourceAccurate)
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

    override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
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

    override func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: StructDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: EnumCaseDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: DeinitializerDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: SubscriptDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: VariableDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: TypealiasDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: AssociatedtypeDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: OperatorDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: PrecedenceGroupDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: ImportDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override func visitPost(_ node: OptionalBindingConditionSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }
}

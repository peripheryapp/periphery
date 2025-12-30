import Foundation
import Shared
import SourceGraph
import SwiftParser
import SwiftSyntax
import SystemPackage

public protocol PeripherySyntaxVisitor {
    init(sourceLocationBuilder: SourceLocationBuilder, swiftVersion: SwiftVersion)

    func visit(_ node: ActorDeclSyntax)
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
    func visit(_ node: TypeAliasDeclSyntax)
    func visit(_ node: AssociatedTypeDeclSyntax)
    func visit(_ node: OperatorDeclSyntax)
    func visit(_ node: PrecedenceGroupDeclSyntax)
    func visit(_ node: ImportDeclSyntax)
    func visit(_ node: OptionalBindingConditionSyntax)
    func visit(_ node: FunctionCallExprSyntax)

    func visitPost(_ node: ActorDeclSyntax)
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
    func visitPost(_ node: TypeAliasDeclSyntax)
    func visitPost(_ node: AssociatedTypeDeclSyntax)
    func visitPost(_ node: OperatorDeclSyntax)
    func visitPost(_ node: PrecedenceGroupDeclSyntax)
    func visitPost(_ node: ImportDeclSyntax)
    func visitPost(_ node: OptionalBindingConditionSyntax)
    func visitPost(_ node: FunctionCallExprSyntax)
}

public extension PeripherySyntaxVisitor {
    func visit(_: ActorDeclSyntax) {}
    func visit(_: ClassDeclSyntax) {}
    func visit(_: ProtocolDeclSyntax) {}
    func visit(_: StructDeclSyntax) {}
    func visit(_: EnumDeclSyntax) {}
    func visit(_: EnumCaseDeclSyntax) {}
    func visit(_: ExtensionDeclSyntax) {}
    func visit(_: FunctionDeclSyntax) {}
    func visit(_: InitializerDeclSyntax) {}
    func visit(_: DeinitializerDeclSyntax) {}
    func visit(_: SubscriptDeclSyntax) {}
    func visit(_: VariableDeclSyntax) {}
    func visit(_: TypeAliasDeclSyntax) {}
    func visit(_: AssociatedTypeDeclSyntax) {}
    func visit(_: OperatorDeclSyntax) {}
    func visit(_: PrecedenceGroupDeclSyntax) {}
    func visit(_: ImportDeclSyntax) {}
    func visit(_: OptionalBindingConditionSyntax) {}
    func visit(_: FunctionCallExprSyntax) {}

    func visitPost(_: ActorDeclSyntax) {}
    func visitPost(_: ClassDeclSyntax) {}
    func visitPost(_: ProtocolDeclSyntax) {}
    func visitPost(_: StructDeclSyntax) {}
    func visitPost(_: EnumDeclSyntax) {}
    func visitPost(_: EnumCaseDeclSyntax) {}
    func visitPost(_: ExtensionDeclSyntax) {}
    func visitPost(_: FunctionDeclSyntax) {}
    func visitPost(_: InitializerDeclSyntax) {}
    func visitPost(_: DeinitializerDeclSyntax) {}
    func visitPost(_: SubscriptDeclSyntax) {}
    func visitPost(_: VariableDeclSyntax) {}
    func visitPost(_: TypeAliasDeclSyntax) {}
    func visitPost(_: AssociatedTypeDeclSyntax) {}
    func visitPost(_: OperatorDeclSyntax) {}
    func visitPost(_: PrecedenceGroupDeclSyntax) {}
    func visitPost(_: ImportDeclSyntax) {}
    func visitPost(_: OptionalBindingConditionSyntax) {}
    func visitPost(_: FunctionCallExprSyntax) {}
}

public final class MultiplexingSyntaxVisitor: SyntaxVisitor {
    public let sourceFile: SourceFile
    public let syntax: SourceFileSyntax
    public let locationConverter: SourceLocationConverter
    let sourceLocationBuilder: SourceLocationBuilder
    let swiftVersion: SwiftVersion

    private var visitors: [PeripherySyntaxVisitor] = []

    public required init(file: SourceFile, swiftVersion: SwiftVersion) throws {
        sourceFile = file
        let source = try String(contentsOf: file.path.url)
        syntax = Parser.parse(source: source)
        locationConverter = SourceLocationConverter(fileName: file.path.string, tree: syntax)
        sourceLocationBuilder = SourceLocationBuilder(file: file, locationConverter: locationConverter)
        self.swiftVersion = swiftVersion
        super.init(viewMode: .sourceAccurate)
    }

    public func add<T: PeripherySyntaxVisitor>(_ visitorType: T.Type) -> T {
        let visitor = visitorType.init(sourceLocationBuilder: sourceLocationBuilder, swiftVersion: swiftVersion)
        visitors.append(visitor)
        return visitor
    }

    public func visit() {
        walk(syntax)
    }

    public func parseComments() -> [CommentCommand] {
        CommentCommand.parseCommands(in: syntax.leadingTrivia)
    }

    override public func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        visitors.forEach { $0.visit(node) }
        return .visitChildren
    }

    override public func visitPost(_ node: ActorDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: ClassDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: ProtocolDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: StructDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: EnumDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: EnumCaseDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: ExtensionDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: FunctionDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: InitializerDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: DeinitializerDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: SubscriptDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: VariableDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: TypeAliasDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: AssociatedTypeDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: OperatorDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: PrecedenceGroupDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: ImportDeclSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: OptionalBindingConditionSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }

    override public func visitPost(_ node: FunctionCallExprSyntax) {
        visitors.forEach { $0.visitPost(node) }
    }
}

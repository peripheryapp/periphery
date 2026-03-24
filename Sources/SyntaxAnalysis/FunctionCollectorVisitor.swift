import Shared
import SwiftSyntax

/// Collects top-level function and initializer syntax nodes during the shared
/// MultiplexingSyntaxVisitor walk, so UnusedParameterParser can skip its own
/// full-tree traversal and parse only the pre-collected nodes.
public final class FunctionCollectorVisitor: PeripherySyntaxVisitor {
    public private(set) var functionDecls: [FunctionDeclSyntax] = []
    public private(set) var initializerDecls: [InitializerDeclSyntax] = []

    private var depth = 0

    public init(sourceLocationBuilder _: SourceLocationBuilder, swiftVersion _: SwiftVersion) {}

    public func visit(_ node: FunctionDeclSyntax) {
        if depth == 0 {
            functionDecls.append(node)
        }
        depth += 1
    }

    public func visitPost(_: FunctionDeclSyntax) {
        depth -= 1
    }

    public func visit(_ node: InitializerDeclSyntax) {
        if depth == 0 {
            initializerDecls.append(node)
        }
        depth += 1
    }

    public func visitPost(_: InitializerDeclSyntax) {
        depth -= 1
    }
}

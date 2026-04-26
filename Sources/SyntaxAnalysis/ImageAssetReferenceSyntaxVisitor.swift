import Foundation
import Shared
import SourceGraph
import SwiftSyntax

public final class ImageAssetReferenceSyntaxVisitor: PeripherySyntaxVisitor {
    public private(set) var references: Set<ImageAssetReference> = []

    private let sourceLocationBuilder: SourceLocationBuilder

    public required init(sourceLocationBuilder: SourceLocationBuilder, swiftVersion _: SwiftVersion) {
        self.sourceLocationBuilder = sourceLocationBuilder
    }

    public func visit(_ node: FunctionCallExprSyntax) {
        guard isImageAssetCall(node),
              let literal = firstStringLiteralArgument(in: node)
        else { return }

        references.insert(
            ImageAssetReference(
                name: literal.value,
                location: sourceLocationBuilder.location(at: literal.position),
                source: .swift
            )
        )
    }

    // MARK: - Private

    private func isImageAssetCall(_ node: FunctionCallExprSyntax) -> Bool {
        let calledExpression = node.calledExpression.trimmedDescription
        let firstArgument = node.arguments.first
        let firstLabel = firstArgument?.label?.text

        if ["Image", "UIImage", "NSImage"].contains(calledExpression) {
            return firstLabel == nil || firstLabel == "named"
        }

        if calledExpression.hasSuffix(".init") {
            let initializedType = calledExpression.dropLast(".init".count)
            if ["Image", "UIImage", "NSImage"].contains(String(initializedType)) {
                return firstLabel == nil || firstLabel == "named"
            }
        }

        if ["ImageResource", "UIImageResource"].contains(calledExpression) {
            return firstLabel == "name"
        }

        return false
    }

    private func firstStringLiteralArgument(in node: FunctionCallExprSyntax) -> (value: String, position: AbsolutePosition)? {
        guard let expression = node.arguments.first?.expression.as(StringLiteralExprSyntax.self),
              expression.segments.count == 1,
              let segment = expression.segments.first?.as(StringSegmentSyntax.self)
        else { return nil }

        return (segment.content.text, expression.positionAfterSkippingLeadingTrivia)
    }
}

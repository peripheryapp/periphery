import Foundation
import Shared
import SwiftSyntax

/// Collects string keys used for localization in Swift source files.
///
/// Detects usages of:
/// - `NSLocalizedString("key", ...)`
/// - `String(localized: "key", ...)`
/// - `LocalizedStringKey("key")`
/// - `LocalizedStringResource("key", ...)`
/// - `Text("key")`
public final class LocalizedStringSyntaxVisitor: PeripherySyntaxVisitor {
    public private(set) var usedStringKeys: Set<String> = []

    public init(sourceLocationBuilder _: SourceLocationBuilder, swiftVersion _: SwiftVersion) {}

    public func visit(_ node: FunctionCallExprSyntax) {
        // Get the function name being called
        let calledExpression = node.calledExpression

        // Handle NSLocalizedString("key", ...)
        if let identifier = calledExpression.as(DeclReferenceExprSyntax.self),
           identifier.baseName.text == "NSLocalizedString"
        {
            if let firstArg = node.arguments.first,
               let stringLiteral = firstArg.expression.as(StringLiteralExprSyntax.self),
               let key = extractStringValue(from: stringLiteral)
            {
                usedStringKeys.insert(key)
            }
            return
        }

        // Handle String(localized: "key", ...) or String(localized: "key", table: "table", ...)
        if let identifier = calledExpression.as(DeclReferenceExprSyntax.self),
           identifier.baseName.text == "String"
        {
            if let localizedArg = node.arguments.first(where: { $0.label?.text == "localized" }),
               let stringLiteral = localizedArg.expression.as(StringLiteralExprSyntax.self),
               let key = extractStringValue(from: stringLiteral)
            {
                usedStringKeys.insert(key)
            }
            return
        }

        // Handle LocalizedStringKey("key") and LocalizedStringResource("key", ...)
        if let identifier = calledExpression.as(DeclReferenceExprSyntax.self),
           identifier.baseName.text == "LocalizedStringKey" || identifier.baseName.text == "LocalizedStringResource"
        {
            if let firstArg = node.arguments.first,
               firstArg.label == nil, // Unlabeled first argument
               let stringLiteral = firstArg.expression.as(StringLiteralExprSyntax.self),
               let key = extractStringValue(from: stringLiteral)
            {
                usedStringKeys.insert(key)
            }
            return
        }

        // Handle SwiftUI Text("key") - first unlabeled string argument is localized
        if let identifier = calledExpression.as(DeclReferenceExprSyntax.self),
           identifier.baseName.text == "Text"
        {
            if let firstArg = node.arguments.first,
               firstArg.label == nil, // Unlabeled first argument
               let stringLiteral = firstArg.expression.as(StringLiteralExprSyntax.self),
               let key = extractStringValue(from: stringLiteral)
            {
                usedStringKeys.insert(key)
            }
            return
        }

        // Handle member access like Bundle.main.localizedString(forKey: "key", ...)
        if let memberAccess = calledExpression.as(MemberAccessExprSyntax.self),
           memberAccess.declName.baseName.text == "localizedString"
        {
            if let forKeyArg = node.arguments.first(where: { $0.label?.text == "forKey" }),
               let stringLiteral = forKeyArg.expression.as(StringLiteralExprSyntax.self),
               let key = extractStringValue(from: stringLiteral)
            {
                usedStringKeys.insert(key)
            }
            return
        }
    }

    // MARK: - Private

    /// Extracts the string value from a string literal, handling simple cases.
    /// Returns nil for string interpolations since they can't be matched to static keys.
    private func extractStringValue(from literal: StringLiteralExprSyntax) -> String? {
        // Only handle simple string literals, not interpolations
        guard literal.segments.count == 1,
              let segment = literal.segments.first,
              let stringSegment = segment.as(StringSegmentSyntax.self)
        else {
            return nil
        }

        return stringSegment.content.text
    }
}

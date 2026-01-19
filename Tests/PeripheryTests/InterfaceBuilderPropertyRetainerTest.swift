import Foundation
@testable import SourceGraph
import XCTest

/// Tests for InterfaceBuilderPropertyRetainer's Swift-to-Objective-C selector conversion.
final class InterfaceBuilderPropertyRetainerTest: XCTestCase {
    // MARK: - No Parameters

    func testNoParameters() {
        // func confirmTapped() → confirmTapped (no colon)
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("confirmTapped()"), "confirmTapped")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("doSomething()"), "doSomething")
    }

    // MARK: - Unnamed First Parameter (using _)

    func testUnnamedFirstParameter() {
        // func click(_ sender: Any) → click:
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("click(_:)"), "click:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("handleTap(_:)"), "handleTap:")
    }

    // MARK: - Named First Parameter

    func testNamedFirstParameter() {
        // func colorTapped(sender: Any) → colorTappedWithSender:
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("colorTapped(sender:)"), "colorTappedWithSender:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("configure(model:)"), "configureWithModel:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("update(value:)"), "updateWithValue:")
    }

    // MARK: - Multiple Parameters with Unnamed First

    func testMultipleParametersUnnamedFirst() {
        // func handleTap(_:forEvent:) → handleTap:forEvent:
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("handleTap(_:forEvent:)"), "handleTap:forEvent:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("doSomething(_:withValue:andExtra:)"), "doSomething:withValue:andExtra:")
    }

    // MARK: - Multiple Parameters with Named First

    func testMultipleParametersNamedFirst() {
        // func configure(model:animated:) → configureWithModel:animated:
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("configure(model:animated:)"), "configureWithModel:animated:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("update(sender:completion:)"), "updateWithSender:completion:")
    }

    // MARK: - Preposition First Parameters (no "With" prefix)

    func testPrepositionFirstParameter() {
        // Prepositions are just capitalized, not prefixed with "With"
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(for:)"), "actionFor:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(with:)"), "actionWith:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(using:)"), "actionUsing:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(by:)"), "actionBy:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(to:)"), "actionTo:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(at:)"), "actionAt:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(in:)"), "actionIn:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(on:)"), "actionOn:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(from:)"), "actionFrom:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(into:)"), "actionInto:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(after:)"), "actionAfter:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(before:)"), "actionBefore:")
    }

    func testWithPrefixedFirstParameter() {
        // Labels starting with "with" are just capitalized (no double "With")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(withSender:)"), "actionWithSender:")
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("action(withValue:)"), "actionWithValue:")
    }

    // MARK: - Edge Cases

    func testSingleLetterParameter() {
        // func tap(x:) → tapWithX:
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("tap(x:)"), "tapWithX:")
    }

    func testMethodWithNoParentheses() {
        // Should return as-is (shouldn't happen in practice, but handles edge case)
        XCTAssertEqual(InterfaceBuilderPropertyRetainer.swiftNameToSelector("someProperty"), "someProperty")
    }
}

import XCTest
import PathKit
@testable import PeripheryKit

class SourceGraphTestCase: XCTestCase {
    var graph: SourceGraph!

    func XCTAssertNotReferenced(_ description: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = graph.allDeclarations.first(where: {
            $0.kind == description.kind && $0.name == description.name
        }) else {
            XCTFail("Expected \(description) to exist.", file: file, line: line)
            return
        }

        // We don't check dereferencedDeclarations as it's pruned of certain redundant declarations.
        let isReferenced = graph.referencedDeclarations.contains(declaration)
        XCTAssertTrue(!isReferenced, "Expected \(description) to not be referenced.", file: file, line: line)
    }

    func XCTAssertReferenced(_ description: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        let isReferenced = graph.referencedDeclarations.contains {
            $0.kind == description.kind && $0.name == description.name
        }

        XCTAssertTrue(isReferenced, "Expected \(description) to be referenced.", file: file, line: line)
    }

    func XCTAssertReferenced(_ declaration: Declaration, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(graph.referencedDeclarations.contains(declaration), "Expected \(declaration) to be referenced.", file: file, line: line)
    }

    func XCTAssertReferenced(_ description: DeclarationDescription, descendentOf parentDescriptions: DeclarationDescription..., file: StaticString = #file, line: UInt = #line) {
        let parentDeclaration = find(parentDescriptions)

        XCTAssertNotNil(parentDeclaration, "Parent declaration not found: \(parentDescriptions)", file: file, line: line)

        if let parentDeclaration = parentDeclaration {
            let descendent = find(description, in: parentDeclaration.descendentDeclarations)

            XCTAssertNotNil(descendent, "Descendent declaration not found: \(description)", file: file, line: line)

            if let descendent = descendent {
                XCTAssertReferenced(descendent, file: file, line: line)
            }
        }
    }

    func XCTAssertNotReferenced(_ description: DeclarationDescription, descendentOf parentDescriptions: DeclarationDescription..., file: StaticString = #file, line: UInt = #line) {
        let parentDeclaration = find(parentDescriptions)

        XCTAssertNotNil(parentDeclaration, "Parent declaration not found: \(parentDescriptions)", file: file, line: line)

        if let parentDeclaration = parentDeclaration {
            let referencedDescendents = parentDeclaration.descendentDeclarations.intersection(graph.referencedDeclarations)
            let descendent = find(description, in: referencedDescendents)

            XCTAssertNil(descendent, "Descendent declaration should not be referenced: \(description)", file: file, line: line)
        }
    }

    func XCTAssertIgnored(_ description: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        let declaration = find(description)

        XCTAssertNotNil(declaration, "Declaration not found: \(description)", file: file, line: line)

        if let declaration = declaration {
            XCTAssertTrue(graph.ignoredDeclarations.contains(declaration), "Expected \(declaration) to be ignored.", file: file, line: line)
        }
    }

    func find(_ description: DeclarationDescription, in collection: Set<Declaration>? = nil) -> Declaration? {
        return (collection ?? graph.allDeclarations).first { $0.kind == description.kind && $0.name == description.name }
    }

    func find(_ descriptions: [DeclarationDescription]) -> Declaration? {
        var parentDecls: Set<Declaration> = graph.allDeclarations
        var decl: Declaration?

        for description in descriptions {
            decl = find(description, in: parentDecls)
            parentDecls = decl?.declarations ?? []
        }

        return decl
    }

    func get(_ param: String, _ function: String, _ cls: String, _ kind: Declaration.Kind = .class) -> Declaration? {
        let decl = find((kind, cls)) ?? find((.protocol, cls))
        let funcDecl = Declaration.Kind.functionKinds.mapFirst {
            find(($0, function), in: decl!.declarations)
        }
        return find((.varParameter, param), in: funcDecl!.unusedParameters)
    }

    typealias DeclarationDescription = (kind: Declaration.Kind, name: String)
}

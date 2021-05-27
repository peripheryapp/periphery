import XCTest
import PathKit
import PeripheryKit

open class SourceGraphTestCase: XCTestCase {
    open var graph: SourceGraph!

    public func XCTAssertNotReferenced(_ description: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description) else { return }

        if !graph.unreachableDeclarations.contains(declaration) {
            XCTFail("Expected declaration to not be referenced: \(declaration)", file: file, line: line)
        }
    }

    public func XCTAssertReferenced(_ description: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize(description) else { return }

        if !graph.reachableDeclarations.contains(declaration) {
            XCTFail("Expected declaration to be referenced: \(declaration)", file: file, line: line)
        }
    }

    public func XCTAssertReferenced(_ description: DeclarationDescription, descendentOf parentDescriptions: DeclarationDescription..., file: StaticString = #file, line: UInt = #line) {
        guard let parentDeclaration = materialize(parentDescriptions),
              let descendent = materialize(description, in: parentDeclaration.descendentDeclarations)
        else { return }

        if !graph.reachableDeclarations.contains(descendent) {
            XCTFail("Expected declaration to be referenced: \(descendent)", file: file, line: line)
        }
    }

    public func XCTAssertNotReferenced(_ description: DeclarationDescription, descendentOf parentDescriptions: DeclarationDescription..., file: StaticString = #file, line: UInt = #line) {
        guard let parentDeclaration = materialize(parentDescriptions),
              let descendent = materialize(description, in: parentDeclaration.descendentDeclarations)
        else { return }

        if graph.reachableDeclarations.contains(descendent) {
            XCTFail("Expected descendent declaration to not be referenced: \(descendent)", file: file, line: line)
        }
    }

    public func XCTAssertRedundantProtocol(_ name: String, implementedBy conformances: DeclarationDescription..., file: StaticString = #file, line: UInt = #line) {
        guard let declaration = materialize((.protocol, name)) else { return }

        if let references = graph.redundantProtocols[declaration] {
            let decls = references.compactMap { $0.parent }

            for conformance in conformances {
                if !decls.contains(where: { $0.kind == conformance.kind && $0.name == conformance.name }) {
                    XCTFail("Expected \(conformance) to implement protocol '\(name)'.")
                }
            }
        } else {
            XCTFail("Expected '\(name)' to be redundant.", file: file, line: line)
        }
    }

    public func XCTAssertNotRedundantProtocol(_ name: String, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = find((.protocol, name)) else {
            XCTFail("Expected protocol '\(name)' to exist.", file: file, line: line)
            return
        }

        if graph.redundantProtocols.keys.contains(declaration) {
            XCTFail("Expected '\(name)' to not be redundant.", file: file, line: line)
        }
    }

    public func find(_ description: DeclarationDescription, in collection: Set<Declaration>? = nil) -> Declaration? {
        return (collection ?? graph.allDeclarations).first { $0.kind == description.kind && $0.name == description.name }
    }

    public func get(_ param: String, _ function: String, _ cls: String, _ kind: Declaration.Kind = .class) -> Declaration? {
        let decl = find((kind, cls)) ?? find((.protocol, cls))
        let funcDecl = Declaration.Kind.functionKinds.mapFirst {
            find(($0, function), in: decl!.declarations)
        }
        return find((.varParameter, param), in: funcDecl!.unusedParameters)
    }

    public func materialize(_ descriptions: [DeclarationDescription], in declarations: Set<Declaration>? = nil) -> Declaration? {
        var parentDecls = declarations ?? graph.allDeclarations
        var decl: Declaration?

        for description in descriptions.reversed() {
            guard let decl_ = materialize(description, in: parentDecls) else { return nil }
            decl = decl_
            parentDecls = decl?.declarations ?? []
        }

        return decl
    }

    public func materialize(_ description: DeclarationDescription, in collection: Set<Declaration>? = nil, file: StaticString = #file, line: UInt = #line) -> Declaration? {
        guard let decl = find(description, in: collection ?? graph.allDeclarations) else {
            XCTFail("Declaration not found: \(description).", file: file, line: line)
            return nil
        }

        return decl
    }

    public typealias DeclarationDescription = (kind: Declaration.Kind, name: String)
}

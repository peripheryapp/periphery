import Configuration
import Shared
@testable import SourceGraph
import SystemPackage
import XCTest

final class SourceGraphConflictTests: XCTestCase {
    func testAddThrowsOnUsrConflict() throws {
        let graph = SourceGraph(
            configuration: Configuration()
        )
        let usr = "s:4Test3fooyyF"

        let firstDeclaration = makeDeclaration(
            in: graph,
            name: "foo",
            usr: usr,
            path: "/tmp/First.swift",
            modules: ["FirstModule"]
        )
        let conflictingDeclaration = makeDeclaration(
            in: graph,
            name: "foo",
            usr: usr,
            path: "/tmp/Second.swift",
            modules: ["SecondModule"]
        )

        try graph.add(firstDeclaration)

        XCTAssertThrowsError(try graph.add(conflictingDeclaration)) { error in
            guard case let PeripheryError.sourceGraphIntegrityError(message) = error else {
                return XCTFail("Unexpected error: \(error)")
            }

            XCTAssertTrue(message.contains(usr))
            XCTAssertTrue(message.contains("FirstModule"))
            XCTAssertTrue(message.contains("SecondModule"))
        }

        XCTAssertTrue(graph.declaration(withUsr: usr) === firstDeclaration)
    }

    private func makeDeclaration(
        in graph: SourceGraph,
        name: String,
        usr: String,
        path: String,
        modules: Set<String>
    ) -> Declaration {
        let file = SourceFile(path: FilePath(path), modules: modules)
        let usrID = graph.usrInterner.intern(usr)
        return Declaration(
            name: name,
            kind: .functionFree,
            usrs: [usr],
            usrIDs: [usrID],
            location: Location(file: file, line: 1, column: 1)
        )
    }
}

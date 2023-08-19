import XCTest
import Shared
import SystemPackage
@testable import TestShared
@testable import PeripheryKit

final class RemovalTest: FixtureSourceGraphTestCase {
    private static let outputBasePath = FilePath("/tmp/periphery/RemovalTest")

    static override func setUp() {
        super.setUp()

        configuration.targets = ["RemovalFixtures"]

        _ = try? Shell.shared.exec(["rm", "-rf", outputBasePath.string])
        _ = try? Shell.shared.exec(["mkdir", "-p", outputBasePath.string])
        configuration.removalOutputBasePath = outputBasePath

        build(driver: SPMProjectDriver.self)
    }

    func testRootDeclaration() throws {
        try assertOutput(
            """
            public class UsedRootDeclaration1 {}
            public class UsedRootDeclaration2 {}
            """
        )
    }

    func testSimpleProperty() throws {
        try assertOutput(
            """
            public class SimplePropertyRemoval {
                public var used = 1
            }
            """
        )
    }

    func testMultipleBindingProperty() throws {
        // TOOD
    }

    func testFunction() throws {
        try assertOutput(
            """
            public class FunctionRemoval {
                public func used1() {}
            }
            
            extension FunctionRemoval {
                public func used2() {}
            }
            """
        )
    }

    func testUnusedTypealias() throws {
        try assertOutput(
            """
            public enum CustomTypes {
            }
            """
        )
    }

    func testUnusedEnumCase() throws {
        try assertOutput(
            """
            enum EnumCaseRemoval {
                case used
            }

            public class EnumCaseRemovalRetainer {
                public func retain() {
                    _ = EnumCaseRemoval.used
                }
            }
            """
        )
    }

    func testUnusedEnumInListCase() throws {
        try assertOutput(
            """
            enum EnumInListCaseRemoval {
                case used1, used2
            }

            public class EnumInListCaseRemovalRetainer {
                public func retain() {
                    _ = EnumInListCaseRemoval.used1
                    _ = EnumInListCaseRemoval.used2
                }
            }
            """
        )
    }

    func testUnusedExtension() throws {
        try assertNoFile()
    }

    func testUnusedInitializer() throws {
        try assertOutput(
            """
            public class UnusedInitializer {
                public init(used: Int) {}
            }
            """
        )
    }

    func testUnusedNestedDeclaration() throws {
        try assertOutput(
            """
            public class NestedDeclaration {
                public class NestedDeclarationInner {
                }
            }
            """
        )
    }

    func testUnusedSubscript() throws {
        try assertOutput(
            """
            public class UnusedSubscript {
            }
            """
        )
    }

    func testRedundantProtocol() throws {
        try assertOutput(
            """
            protocol RedundantProtocol3_Existential1 {}
            protocol RedundantProtocol3_Existential2 {}
            class RedundantProtocolClass1: CustomStringConvertible, RedundantProtocol3_Existential1, RedundantProtocol3_Existential2 {
                var description: String = ""
            }
            class RedundantProtocolClass2 {}
            class RedundantProtocolClass3 {
                class RedundantProtocolClass4: CustomStringConvertible {
                    var description: String = ""
                }
            }

            public class RedundantProtocolRetainer {
                public func retain() {
                    _ = RedundantProtocolClass1()
                    _ = RedundantProtocolClass2.self
                    _ = RedundantProtocolClass3.RedundantProtocolClass4.self
                }
            }
            """
        )
    }

    func testUnusedNestedTypeWithExtension() throws {
        try assertNoFile()
    }

    func testUnusedCodableProperty() throws {
        try assertOutput(
            """
            public class UnusedCodableProperty: Codable {
                public var used: String?

                enum CodingKeys: CodingKey {
                    case used
                    case unused
                }
            }
            """
        )
    }

    // MARK: - Misc.

    func testLeadingTriviaSplitting() throws {
        try assertOutput(
            """
            // Trivia to remain, 1

            // Trivia to remain, 2


            public class LeadingTriviaSplittingUsed {}
            """
        )
    }

    func testEmptyExtension() throws {
        try assertOutput(
            """
            public class EmptyExtension {}
            public protocol EmptyExtensionProtocol {}
            extension EmptyExtension: EmptyExtensionProtocol {}
            """
        )
    }

    func testEmptyFile() throws {
        try assertNoFile()
    }

    // MARK: - Redundant Public Accessibility

    func testClassRedundantPublicAccessibility() throws {
        try assertOutput(
            retainPublic: false,
            disableRedundantPublicAnalysis: false,
            """
            // periphery:ignore
            final class ClassRedundantPublicAccessibilityRetainer {
                // periphery:ignore
                func retain() {
                    ClassRedundantPublicAccessibility().someFunc()
                }
            }

            final class ClassRedundantPublicAccessibility {
                func someFunc() {}
            }
            """
        )
    }

    func testFunctionRedundantPublicAccessibility() throws {
        try assertOutput(
            retainPublic: false,
            disableRedundantPublicAnalysis: false,
            """
            // periphery:ignore
            final class FunctionRedundantPublicAccessibilityRetainer {
                // periphery:ignore
                func retain() {
                    somePublicFunc()
                }
            }

            func somePublicFunc() {}
            """
        )
    }

    func testSubscriptRedundantPublicAccessibility() throws {
        try assertOutput(
            retainPublic: false,
            disableRedundantPublicAnalysis: false,
            """
            // periphery:ignore
            final class SubscriptRedundantPublicAccessibilityRetainer {
                // periphery:ignore
                func retain() {
                    _ = SubscriptRedundantPublicAccessibility()[1]
                }
            }

            final class SubscriptRedundantPublicAccessibility {
                subscript(param: Int) -> Int {
                    return 0
                }
            }
            """
        )
    }

    func testPropertyRedundantPublicAccessibility() throws {
        try assertOutput(
            retainPublic: false,
            disableRedundantPublicAnalysis: false,
            """
            // periphery:ignore
            final class PropertyRedundantPublicAccessibilityRetainer {
                // periphery:ignore
                func retain() {
                    _ = somePublicProperty
                }
            }

            let somePublicProperty: Int = 1
            """
        )
    }

    func testInitializerRedundantPublicAccessibility() throws {
        try assertOutput(
            retainPublic: false,
            disableRedundantPublicAnalysis: false,
            """
            // periphery:ignore
            final class InitializerRedundantPublicAccessibilityRetainer {
                // periphery:ignore
                func retain() {
                    _ = InitializerRedundantPublicAccessibility()
                }
            }

            class InitializerRedundantPublicAccessibility {
                init() {}
            }
            """
        )
    }

    func testRedundantPublicAccessibilityWithAttributes() throws {
        try assertOutput(
            retainPublic: false,
            disableRedundantPublicAnalysis: false,
            """
            // periphery:ignore
            private final class Retainer {
                func retain() {
                    redundantPublicAccessibilityWithAttributes()
                }
            }

            @available(*, message: "hi mum")
            func redundantPublicAccessibilityWithAttributes() {}
            """
        )
    }

    // MARK: - Private

    private func assertOutput(
        retainPublic: Bool = true,
        disableRedundantPublicAnalysis: Bool = true,
        _ expectedOutput: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let results = analyze(
            retainPublic: retainPublic,
            disableRedundantPublicAnalysis: disableRedundantPublicAnalysis
        ) {}
        try ScanResultRemover().remove(results: results)

        let outputPath = Self.outputBasePath.appending(testFixturePath.lastComponent!)
        let output = try String(contentsOf: outputPath.url)

        XCTAssertEqual(output.trimmed, expectedOutput, file: file, line: line)
    }

    private func assertNoFile() throws {
        let results = analyze(
            retainPublic: true,
            disableRedundantPublicAnalysis: false
        ) {}
        try ScanResultRemover().remove(results: results)

        let outputPath = Self.outputBasePath.appending(testFixturePath.lastComponent!)
        XCTAssertFalse(FileManager.default.fileExists(atPath: outputPath.string))
    }
}

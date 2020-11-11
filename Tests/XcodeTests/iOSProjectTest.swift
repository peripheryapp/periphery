import XCTest
import PathKit
import Shared
import TestShared
@testable import XcodeSupport
@testable import PeripheryKit

class iOSProjectTest: SourceGraphTestCase {
    static private var graph: SourceGraph!

    override var graph: SourceGraph! {
        get {
            Self.graph
        }
        set {
            Self.graph = newValue
        }
    }

    override static func setUp() {
        super.setUp()

        let project = try! XcodeProject.make(path: iOSProjectPath)

        let configuration: Configuration = inject()
        configuration.outputFormat = .json

        let driver = XcodeProjectDriver(
            logger: inject(),
            configuration: configuration,
            xcodebuild: inject(),
            project: project,
            schemes: [try! XcodeScheme.make(project: project, name: "iOSProject")],
            targets: project.targets
        )

        try! driver.build()
        graph = SourceGraph()
        try! driver.index(graph: graph)
        try! Analyzer.perform(graph: graph)
    }

    func testRetainsMainAppEntryPoint() {
        #if swift(>=5.3)
        XCTAssertReferenced((.struct, "iOSProjectApp"))
        #else
        XCTAssertReferenced((.class, "AppDelegate"))
        #endif
    }

    func testRetainsSceneDelegateReferencedInInfoPlist() {
        XCTAssertReferenced((.class, "SceneDelegate"))
    }

    func testRetainsXibReferencedClass() {
        XCTAssertReferenced((.class, "XibViewController"))
        XCTAssertReferenced((.varInstance, "button"), descendentOf: (.class, "XibViewController"))
        XCTAssertReferenced((.functionMethodInstance, "click(_:)"), descendentOf: (.class, "XibViewController"))
    }

    func testRetainsStoryboardReferencedClass() {
        XCTAssertReferenced((.class, "StoryboardViewController"))
        XCTAssertReferenced((.varInstance, "button"), descendentOf: (.class, "StoryboardViewController"))
        XCTAssertReferenced((.functionMethodInstance, "click(_:)"), descendentOf: (.class, "StoryboardViewController"))
    }

    func testRetainsSwiftUIPreviewProviders() {
        XCTAssertReferenced((.struct, "ContentView_Previews"))
    }

    func testRetainsMethodReferencedByObjcSelector() {
        XCTAssertReferenced((.functionMethodInstance, "targetMethod()"), descendentOf: (.class, "XibViewController"))
    }
}

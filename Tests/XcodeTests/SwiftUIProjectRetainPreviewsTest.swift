import Configuration
@testable import TestShared

final class SwiftUIProjectRetainPreviewsTest: XcodeSourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        let configuration = Configuration()
        configuration.schemes = ["SwiftUIProject"]
        configuration.retainSwiftUIPreviews = true

        build(projectPath: SwiftUIProjectPath, configuration: configuration)
        index(configuration: configuration)
    }

    func testRetainsPreviewProvider() {
        // With flag enabled, PreviewProvider structs should be retained
        assertReferenced(.struct("ContentView_Previews"))
    }

    func testRetainsPreviewMacroView() {
        // With flag enabled, views referenced from #Preview should be retained
        assertReferenced(.struct("DetailView"))
    }

    func testRetainsNestedTypeFromPreviewMacro() {
        // With flag enabled, nested types referenced from #Preview should be retained
        assertReferenced(.struct("PreviewHelpers")) {
            self.assertReferenced(.struct("NestedHelper"))
        }
    }
}

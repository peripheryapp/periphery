import Foundation
import SystemPackage
@testable import TestShared

var UIKitProjectPath: FilePath {
    return ProjectRootPath.appending("Tests/XcodeTests/UIKitProject/UIKitProject.xcodeproj")
}

var SwiftUIProjectPath: FilePath {
    return ProjectRootPath.appending("Tests/XcodeTests/SwiftUIProject/SwiftUIProject.xcodeproj")
}

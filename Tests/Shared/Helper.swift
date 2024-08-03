import Foundation
import SystemPackage

var ProjectRootPath: FilePath {
    FilePath(#filePath).appending("../../..").lexicallyNormalized()
}

var FixturesProjectPath: FilePath {
    ProjectRootPath.appending("Tests/Fixtures")
}

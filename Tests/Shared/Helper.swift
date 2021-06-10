import Foundation
import SystemPackage

var ProjectRootPath: FilePath {
    FilePath(#filePath).appending("../../..").lexicallyNormalized()
}

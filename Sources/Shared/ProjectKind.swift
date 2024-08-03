import Foundation
import SystemPackage

public enum ProjectKind {
    case xcode(projectPath: FilePath)
    case spm
    case generic(genericProjectConfig: FilePath)
}

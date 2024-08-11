import Foundation
import SystemPackage

public struct Bazel {
    public static var isSupported: Bool {
        FilePath("MODULE.bazel").exists || FilePath("WORKSPACE").exists
    }
}

import Foundation
import SystemPackage
import Shared

public struct SPM {
    static let packageFile = "Package.swift"

    public static var isSupported: Bool {
        Package().exists
    }

    public struct Package {
        let path: FilePath = .current

        var exists: Bool {
            path.appending(packageFile).exists
        }

        func clean() throws {
            try Shell.shared.exec(["swift", "package", "clean"])
        }

        func build(additionalArguments: [String]) throws {
            try Shell.shared.exec(["swift", "build", "--build-tests"] + additionalArguments)
        }
    }
}


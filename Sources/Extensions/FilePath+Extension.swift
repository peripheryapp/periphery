import Foundation
import SystemPackage

public extension FilePath {
    @inlinable static var current: FilePath {
        Self(fileManager.currentDirectoryPath)
    }

    @inlinable
    static func makeAbsolute(_ filePath: String, relativeTo relativePath: FilePath = .current) -> FilePath {
        makeAbsolute(FilePath(filePath), relativeTo: relativePath)
    }

    @inlinable
    static func makeAbsolute(_ filePath: FilePath, relativeTo relativePath: FilePath = .current) -> FilePath {
        var filePath = filePath
        _ = filePath.removePrefix("./")
        return relativePath.pushing(filePath)
    }

    @inlinable
    func makeAbsolute(relativeTo relativePath: FilePath = .current) -> FilePath {
        Self.makeAbsolute(self, relativeTo: relativePath)
    }

    @inlinable var exists: Bool {
        fileManager.fileExists(atPath: lexicallyNormalized().string)
    }

    @inlinable var url: URL {
        URL(fileURLWithPath: lexicallyNormalized().string)
    }

    @inlinable
    func chdir(closure: () throws -> Void) rethrows {
        let previous = Self.current
        _ = fileManager.changeCurrentDirectoryPath(string)
        try closure()
        _ = fileManager.changeCurrentDirectoryPath(previous.string)
    }

    @inlinable
    func relativeTo(_ relativePath: FilePath) -> FilePath {
        let components = lexicallyNormalized().components.map(\.string)
        let relativePathComponents = relativePath.lexicallyNormalized().components.map(\.string)
        var commonPathComponents: [String] = []

        for component in components {
            guard relativePathComponents.count > commonPathComponents.count else { break }
            guard relativePathComponents[commonPathComponents.count] == component else { break }
            commonPathComponents.append(component)
        }

        let relative = Array(repeating: "..", count: relativePathComponents.count - commonPathComponents.count)
        let suffix = components.suffix(components.count - commonPathComponents.count)
        var newComponents = (relative + suffix).compactMap { Component($0) }

        if newComponents.isEmpty {
            newComponents = [Component(".")]
        }

        return FilePath(root: nil, newComponents)
    }

    // MARK: - Private

    @usableFromInline internal static var fileManager: FileManager {
        FileManager.default
    }

    @usableFromInline internal var fileManager: FileManager {
        Self.fileManager
    }
}

extension FilePath: Swift.Comparable {
    public static func < (lhs: FilePath, rhs: FilePath) -> Bool {
        lhs.lexicallyNormalized().string < rhs.lexicallyNormalized().string
    }
}

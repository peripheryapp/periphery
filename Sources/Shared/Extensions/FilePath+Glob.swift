//
//  Created by Eric Firestone on 3/22/16.
//  Copyright © 2016 Square, Inc. All rights reserved.
//  Released under the Apache v2 License.
//
//  Adapted from https://gist.github.com/blakemerryman/76312e1cbf8aec248167
//  Adapted from https://gist.github.com/efirestone/ce01ae109e08772647eb061b3bb387c3

import Foundation
import SystemPackage

public extension FilePath {
    static func glob(_ pattern: String) -> Set<FilePath> {
        let absolutePattern = FilePath(pattern).isRelative ? "\(FilePath.current.string)/\(pattern)" : pattern

        return Glob(
            pattern: absolutePattern,
            blacklistedDirectories: [".build", "node_modules", ".gems", "gems", ".swiftpm"],
            logger: Logger()
        ).paths.mapSet { FilePath($0).lexicallyNormalized() }
    }
}

 /// Finds files on the file system using Bash v4 style pattern matching.
 ///    - A double globstar (**) causes recursive matching in subdirectories.
 ///    - Files from the root directory of the globstar are also included.
 ///      For example, with the pattern "dir/**/*.ext" the file "dir/file.ext" is also included.
 ///    - When the pattern ends with a trailing slash, only directories are matched.
private class Glob {
    private let blacklistedDirectories: [String]
    private let logger: Logger
    private var isDirectoryCache: [String: Bool] = [:]

    fileprivate var paths: Set<String> = []

    init(
        pattern: String,
        blacklistedDirectories: [String],
        logger: Logger
    ) {
        self.blacklistedDirectories = blacklistedDirectories
        self.logger = logger

        let hasTrailingGlobstarSlash = pattern.hasSuffix("**/")
        let includeFiles = !hasTrailingGlobstarSlash
        let patterns = expandGlobstar(pattern: pattern)

        for pattern in patterns {
            var gt = glob_t()

            if executeGlob(pattern: pattern, gt: &gt) {
                populateFiles(gt: gt, includeFiles: includeFiles)
            }

            globfree(&gt)
        }

        clearCaches()
    }

    // MARK: - Private

    private func executeGlob(pattern: UnsafePointer<CChar>, gt: UnsafeMutablePointer<glob_t>) -> Bool {
        glob(pattern, GLOB_TILDE | GLOB_BRACE | GLOB_MARK, nil, gt) == 0
    }

    private func expandGlobstar(pattern: String) -> [String] {
        guard pattern.contains("**") else {
            return [pattern]
        }

        var results = [String]()
        var parts = pattern.components(separatedBy: "**")
        let firstPart = parts.removeFirst()
        var lastPart = parts.joined(separator: "**")

        var directories: [URL]

        if FileManager.default.fileExists(atPath: firstPart) {
            do {
                directories = try exploreDirectories(url: URL(fileURLWithPath: firstPart))
            } catch {
                directories = []
                logger.error("Error parsing file system item: \(error)")
            }
        } else {
            directories = []
        }

        // Include the globstar root directory ("dir/") in a pattern like "dir/**" or "dir/**/"
        if lastPart.isEmpty {
            results.append(firstPart)
        }

        if lastPart.isEmpty {
            lastPart = "*"
        }

        for directory in directories {
            let partiallyResolvedPattern = directory.appendingPathComponent(lastPart)
            let standardizedPattern = (partiallyResolvedPattern.relativePath as NSString).standardizingPath
            results.append(contentsOf: expandGlobstar(pattern: standardizedPattern))
        }

        return results
    }

    private func exploreDirectories(url: URL) throws -> [URL] {
        let subURLs = try FileManager.default.contentsOfDirectory(atPath: url.path).flatMap { subPath -> [URL] in
            if blacklistedDirectories.contains(subPath) {
                return []
            }

            let subPathURL = url.appendingPathComponent(subPath, isDirectory: true)

            guard isDirectory(path: subPathURL.path) else {
                return []
            }

            return try exploreDirectories(url: subPathURL)
        }

        return [url] + subURLs
    }

    private func isDirectory(path: String) -> Bool {
        if let isDirectory = isDirectoryCache[path] {
            return isDirectory
        }

        var isDirectoryBool = ObjCBool(false)
        let isDirectory = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectoryBool) && isDirectoryBool.boolValue
        isDirectoryCache[path] = isDirectory

        return isDirectory
    }

    private func clearCaches() {
        isDirectoryCache.removeAll()
    }

    private func populateFiles(gt: glob_t, includeFiles: Bool) {
#if os(macOS)
        let matches = Int(gt.gl_matchc)
#else
        let matches = Int(gt.gl_pathc)
#endif
        for i in 0..<matches {
            if let path = String(validatingUTF8: gt.gl_pathv[i]!) {
                if !includeFiles {
                    let isDirectory = self.isDirectory(path: path)
                    if !includeFiles && !isDirectory {
                        continue
                    }
                }

                paths.insert(path)
            }
        }
    }
}

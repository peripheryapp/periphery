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
            excludedDirectories: [".build", "node_modules", ".gems", "gems", ".swiftpm"]
        ).paths.mapSet { FilePath($0).lexicallyNormalized() }
    }
}

/// Finds files on the file system using Bash v4 style pattern matching.
///    - A double globstar (`**`) causes recursive matching in subdirectories.
///    - Files from the root directory of the globstar are also included.
///      For example, with the pattern `dir/**/*.ext` the file `dir/file.ext` is also included.
///    - When the pattern ends with a trailing slash, only directories are matched.
private final class Glob {
    private let excludedDirectories: [String]
    private var isDirectoryCache: [String: Bool] = [:]

    fileprivate var paths: Set<String> = []

    init(
        pattern: String,
        excludedDirectories: [String]
    ) {
        self.excludedDirectories = excludedDirectories

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
        expandGlobstar(base: nil, remainder: pattern)
    }

    /// Expands `**` globstar components in `remainder`, relative to the already-resolved `base`
    /// directory. `base` is a concrete path and is never re-examined for globstars, so a directory
    /// literally named `**`or starting with `**` is treated as a literal rather than triggering
    /// unbounded recursion.
    private func expandGlobstar(base: URL?, remainder: String) -> [String] {
        let components = remainder.components(separatedBy: "/")

        guard let globstarIndex = components.firstIndex(of: "**") else {
            return [resolve(base: base, remainder: remainder)]
        }

        let beforeGlobstar = components[..<globstarIndex].joined(separator: "/")
        let afterGlobstar = components[(globstarIndex + 1)...].joined(separator: "/")
        let searchRoot = resolve(base: base, remainder: beforeGlobstar)

        let directories: [URL] = if FileManager.default.fileExists(atPath: searchRoot) {
            exploreDirectories(url: URL(fileURLWithPath: searchRoot))
        } else {
            []
        }

        var results = [String]()

        // Include the globstar root directory ("dir/") in a pattern like "dir/**" or "dir/**/"
        if afterGlobstar.isEmpty {
            results.append(searchRoot)
        }

        let tail = afterGlobstar.isEmpty ? "*" : afterGlobstar

        for directory in directories {
            // Recursion!
            results.append(contentsOf: expandGlobstar(base: directory, remainder: tail))
        }

        return results
    }

    private func resolve(base: URL?, remainder: String) -> String {
        guard let base else { return remainder }
        let joined = remainder.isEmpty ? base : base.appendingPathComponent(remainder)
        return FilePath(joined.path).lexicallyNormalized().string
    }

    private func exploreDirectories(url: URL) -> [URL] {
        let subURLs = try? FileManager.default.contentsOfDirectory(atPath: url.path).flatMap { subPath -> [URL] in
            if excludedDirectories.contains(subPath) {
                return []
            }

            let subPathURL = url.appendingPathComponent(subPath, isDirectory: true)

            guard isDirectory(path: subPathURL.path) else {
                return []
            }

            return exploreDirectories(url: subPathURL)
        }

        return [url] + (subURLs ?? [])
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
        for i in 0 ..< matches {
            if let path = String(validatingUTF8: gt.gl_pathv[i]!) {
                if !includeFiles {
                    let isDirectory = isDirectory(path: path)
                    if !includeFiles, !isDirectory {
                        continue
                    }
                }

                paths.insert(path)
            }
        }
    }
}

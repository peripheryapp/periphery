import Foundation
import SystemPackage

private typealias GroupedResults = [String: [BaselineResult]]

private struct BaselineResult: Codable, Hashable {
    let scanResult: ScanResult
    let text: String
    var key: String { text + scanResult.declaration.kind.rawValue }

    init(scanResult: ScanResult, text: String) {
        self.scanResult = scanResult.withRelativeLocation()
        self.text = text
    }
}

/// A set of scan results that can be used to filter newly detected results.
public struct Baseline: Equatable {
    private let baselineResults: GroupedResults

    /// The stored scan results.
    public var scanResults: [ScanResult] {
        baselineResults.keys.sorted().flatMap({ baselineResults[$0]! }).resultsWithAbsolutePaths
    }

    /// Creates a `Baseline` from a saved file.
    ///
    /// - parameter fromPath: The path to read from.
    public init(fromPath path: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        baselineResults = try JSONDecoder().decode(GroupedResults.self, from: data)
    }

    /// Creates a `Baseline` from a list of results.
    ///
    /// - parameter scanResults: The results for the baseline.
    public init(scanResults: [ScanResult]) {
        self.baselineResults = scanResults.baselineResults.groupedByFile()
    }

    /// Writes a `Baseline` to disk in JSON format.
    ///
    /// - parameter toPath: The path to write to.
    public func write(toPath path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(baselineResults)
        try data.write(to: URL(fileURLWithPath: path))
    }

    /// Filters out scan results that are present in the `Baseline`.
    ///
    /// - parameter scanResults: The scanResults to filter.
    /// - Returns: The new scanResults.
    public func filter(_ scanResults: [ScanResult]) -> [ScanResult] {
        let scanResultsGroupedByFile = Dictionary(grouping: scanResults) {
            $0.declaration.location.file.path.string
        }

        var results: [ScanResult] = []
        for (_, value) in scanResultsGroupedByFile {
            let filteredResults = filterFileResults(value)
            results.append(contentsOf: filteredResults)
        }
        return results
    }

    private func filterFileResults(_ scanResults: [ScanResult]) -> [ScanResult] {
        guard let firstResult = scanResults.first,
              let baselineResults = baselineResults[firstResult.declaration.location.relativeLocation().file.path.string],
              !baselineResults.isEmpty
        else {
            return scanResults
        }

        let relativePathResults = scanResults.baselineResults
        guard relativePathResults != baselineResults else {
            return []
        }

        let resultsByKind = relativePathResults.groupedByKind(
            filteredBy: baselineResults
        )
        let baselineResultsByKind = baselineResults.groupedByKind(
            filteredBy: relativePathResults
        )

        var filteredResults: Set<BaselineResult> = []

        for (kind, results) in resultsByKind {
            guard
                let baselineResults = baselineResultsByKind[kind],
                !baselineResults.isEmpty else {
                filteredResults.formUnion(results)
                continue
            }

            let groupedResults = Dictionary(grouping: results, by: \.key)
            let groupedBaselineResults = Dictionary(grouping: baselineResults, by: \.key)

            for (key, results) in groupedResults {
                guard let baselineResults = groupedBaselineResults[key] else {
                    filteredResults.formUnion(results)
                    continue
                }
                if scanResults.count > baselineResults.count {
                    filteredResults.formUnion(results)
                }
            }
        }

        let scanResultsWithAbsolutePaths = Set(filteredResults.resultsWithAbsolutePaths)
        return scanResults.filter { scanResultsWithAbsolutePaths.contains($0) }
    }
}

// MARK: - Private

private extension Sequence where Element == ScanResult {
    var baselineResults: [BaselineResult] {
        var lines: [String: [String]] = [:]
        var baselineResults: [BaselineResult] = []
        for scanResult in self {
            let absolutePath = scanResult.declaration.location.file.path.string
            let lineNumber = scanResult.declaration.location.line - 1
            guard lineNumber > 0 else {
                baselineResults.append(BaselineResult(scanResult: scanResult, text: ""))
                continue
            }
            if let fileLines = lines[absolutePath] {
                let text = (!fileLines.isEmpty && lineNumber < fileLines.count ) ? fileLines[lineNumber] : ""
                baselineResults.append(BaselineResult(scanResult: scanResult, text: text))
                continue
            }
            let text: String
            if let contents = try? String(contentsOfFile: absolutePath, encoding: .utf8) {
                let fileLines = contents.components(separatedBy: CharacterSet.newlines)
                if lineNumber < fileLines.count {
                    text = fileLines[lineNumber]
                    lines[absolutePath] = fileLines
                } else {
                    text = ""
                }
            } else {
                text = ""
            }
            baselineResults.append(BaselineResult(scanResult: scanResult, text: text))
        }
        return baselineResults
    }
}

private extension Sequence where Element == BaselineResult {
    var resultsWithAbsolutePaths: [ScanResult] {
        map {
            $0.scanResult.withAbsoluteLocation()
        }
    }

    func groupedByFile() -> GroupedResults {
        Dictionary(grouping: self) {
            $0.scanResult.declaration.location.file.path.string
        }
    }

    func groupedByKind() -> GroupedResults {
        Dictionary(grouping: self) { $0.scanResult.declaration.kind.rawValue }
    }

    func groupedByKind(filteredBy existingScanResults: [BaselineResult]) -> GroupedResults {
        Set(self).subtracting(existingScanResults).groupedByKind()
    }
}

private var currentFilePath: FilePath = { .current }()

private extension ScanResult {
    func withRelativeLocation() -> ScanResult {
        ScanResult(
            declaration: declaration.withRelativeLocation(),
            annotation: annotation.withRelativeLocation()
        )
    }

    func withAbsoluteLocation() -> ScanResult {
        ScanResult(
            declaration: declaration.withAbsoluteLocation(),
            annotation: annotation.withAbsoluteLocation()
        )
    }
}

private extension Declaration {
    func withRelativeLocation() -> Declaration {
        Declaration(kind: kind, usrs: usrsWithRelativeLocation(), location: location.relativeLocation())
    }

    func withAbsoluteLocation() -> Declaration {
        Declaration(kind: kind, usrs: usrsWithAbsoluteLocation(), location: location.absoluteLocation())
    }

    private func usrsWithRelativeLocation() -> Set<String> {
        guard kind == .varParameter else {
            return usrs
        }
        return Set(usrs.map {
            let components = $0.split(separator: "-", maxSplits: 3)
            guard components.count == 3 else {
                return $0
            }
            let path = components[2].replacingOccurrences(of: currentFilePath.string + "/", with: "")
            return "\(components[0])-\(components[1])-\(path)"
        })
    }

    private func usrsWithAbsoluteLocation() -> Set<String> {
        guard kind == .varParameter else {
            return usrs
        }
        return Set(usrs.map {
            let components = $0.split(separator: "-", maxSplits: 3)
            guard components.count == 3 else {
                return $0
            }
            let absolutePath = currentFilePath.string + "/" + components[2]
            return "\(components[0])-\(components[1])-\(absolutePath)"
        })
    }
}

private extension SourceLocation {
    func relativeLocation() -> SourceLocation {
        let relativePath = relativePath(to: file.path)
        let file = SourceFile(path: relativePath, modules: file.modules)
        return SourceLocation(file: file, line: line, column: column)
    }

    func absoluteLocation() -> SourceLocation {
        let absolutePath = FilePath(currentFilePath.string + "/" + file.path.string)
        let file = SourceFile(path: absolutePath, modules: file.modules)
        return SourceLocation(file: file, line: line, column: column)
    }

    private func relativePath(to absolutePath: FilePath) -> FilePath {
        // FilePath.relativePath is very slow
        let absolutePathString = absolutePath.string
        let currentPathString = currentFilePath.string
        let relativePathString = absolutePathString.replacingOccurrences(of: currentPathString + "/", with: "")
        let relativePath = FilePath(relativePathString)
        return relativePath
    }
}

private extension ScanResult.Annotation {
    func withRelativeLocation() -> ScanResult.Annotation {
        switch self {
        case .redundantProtocol(let references, let inherited):
            return .redundantProtocol(
                references: Set(references.map { $0.withRelativeLocation() }),
                inherited: inherited
            )
        default:
            return self
        }
    }

    func withAbsoluteLocation() -> ScanResult.Annotation {
        switch self {
        case .redundantProtocol(let references, let inherited):
            return .redundantProtocol(
                references: Set(references.map { $0.withAbsoluteLocation() }),
                inherited: inherited
            )
        default:
            return self
        }
    }
}

private extension Reference {
    func withRelativeLocation() -> Reference {
        Reference(kind: kind, usr: usr, location: location.relativeLocation(), isRelated: isRelated)
    }

    func withAbsoluteLocation() -> Reference {
        Reference(kind: kind, usr: usr, location: location.absoluteLocation(), isRelated: isRelated)
    }
}

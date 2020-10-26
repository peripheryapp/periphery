import Foundation

final class TargetSourceFileUniquenessChecker {
    static func check(targets: Set<XcodeTarget>) throws {
        let pairs = try targets.map { ($0, try $0.sourceFiles()) }
        let sourceFilesByTarget = Dictionary(uniqueKeysWithValues: pairs)
        var universalSet: Set<SourceFile> = []
        var duplicateSourceFiles: Set<SourceFile> = []

        for (_, set) in sourceFilesByTarget {
            let intersection = universalSet.intersection(set)

            if intersection.count > 0 {
                duplicateSourceFiles = duplicateSourceFiles.union(intersection)
            }

            universalSet = universalSet.union(set)
        }

        let logger: Logger = inject()

        for sourceFile in duplicateSourceFiles {
            let targetNames = sourceFilesByTarget.filter { $0.value.contains(sourceFile) }.map { $0.key.name }

            logger.warn("\(sourceFile.path) is a member of multiple targets: \(targetNames.joined(separator: ", ")). This may cause unexpected results.")
        }
    }
}

import Shared
import Logger

struct SourceBranchFilter: OutputFilterable {
    let shell: Shell
    let sourceBranch: String
    let contextualLogger: ContextualLogger

    public init(
        sourceBranch: String,
        shell: Shell,
        contextualLogger: ContextualLogger
    ) {
        self.sourceBranch = sourceBranch
        self.shell = shell
        self.contextualLogger = contextualLogger
    }

    /// Gives you the diff for a single file
    ///
    /// - Parameter file: The file path
    /// - Returns: File diff or error
    private func diff(forFile file: String) -> Result<FileDiff, Error> {
        let parser = DiffParser()
        let diff = Result { try shell.exec(["git", "diff", sourceBranch, "--", file]) }
        return diff.flatMap {
            let diff = parser.parse($0)

            if let fileDiff = diff.first {
                return .success(fileDiff)
            } else {
                contextualLogger.debug("Git diff for \(file) is invalid.")
                return .failure(DiffError.invalidDiff)
            }
        }
    }
    
    private func diff(violation: ScanResult) -> Bool {
        do {
            let changes: FileDiff.Changes = try diff(forFile: violation.declaration.location.file.path.string)
                .get()
                .changes
            
            switch changes {
            case .created:
                return true
            case .deleted:
                return false
            case let .modified(hunks):
                return hunks.contains { hunk in
                    let newLineRanges = hunk.newLineStart ..< hunk.newLineStart + hunk.newLineSpan
                    return newLineRanges.contains(violation.declaration.location.line)
                }
            case .renamed:
                return false
            }
        } catch {
            return false
        }
    }
    
    func filter(_ declarations: [ScanResult]) -> [ScanResult] {
        do {
            try shell.exec(["git", "status"])
            return declarations.filter(diff)
        } catch {
            contextualLogger.debug("Git do not exist in the current directory. Skipping filtering.")
            return declarations
        }
    }
}

extension SourceBranchFilter {
    enum DiffError: Error, Equatable {
        case invalidDiff
    }
}

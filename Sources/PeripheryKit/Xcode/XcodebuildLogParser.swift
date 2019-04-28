import Foundation
import PathKit

struct SwiftcInvocation {
    let arguments: [BuildArgument]
    let files: [String]
}

class XcodebuildLogParser {
    private let lines: [String]

    init(log: String) {
        self.lines = log.split(separator: "\n").map { String($0) }
    }

    func getSwiftcInvocation(target: String, module: String) throws -> SwiftcInvocation {
        let sanitizedModuleName = sanitize(moduleName: module)

        for i in lines.indices {
            if lines[i].trimmed.hasPrefix("CompileSwiftSources") {
                let swiftCommand = lines[i..<lines.endIndex].first { $0.contains("/usr/bin/swiftc") }

                if let swiftCommand = swiftCommand,
                    swiftCommand.contains("-module-name \(sanitizedModuleName) ") {
                    return parseSwiftcInvocation(command: swiftCommand.trimmed)
                }
            }
        }

        throw PeripheryKitError.parseBuildArgumentsFailed(
            target: target,
            moduleName: sanitizedModuleName)
    }

    func sanitize(moduleName: String) -> String {
        let set = CharacterSet.whitespaces.union(.symbols).union(.punctuationCharacters)
        var sanitized = moduleName.components(separatedBy: set).joined(separator: "_")

        // Replace leading decimal
        if let first = sanitized.first {
            let firstSet = CharacterSet(charactersIn: String(first))

            if firstSet.isSubset(of: .decimalDigits) {
                sanitized = "_" + sanitized.dropFirst()
            }
        }

        return sanitized
    }

    // MARK: - Private

    private func parseSwiftcInvocation(command: String) -> SwiftcInvocation {
        let pattern = try! NSRegularExpression(pattern: " (-.+?)(?= -|$)", options: []) // swiftlint:disable:this force_try
        let matches = pattern.matches(in: command, options: [], range: NSRange(command.startIndex..., in: command))
        var arguments: [BuildArgument] = matches.map {
            let range = $0.range(at: 1)
            let pair = String(command[Range(range, in: command)!])
            var (key, value) = splitArgumentPair(pair)
            value = sanitize(argValue: value)
            return BuildArgument(key: key, value: value)
        }

        var files: [String] = []

        // These arguments also contain a list of files to compile, we need to remove them.
        // This may change in the future, but for now they always immediately follow the -j or -num-threads flags.
        if let jobArgumentIndex = arguments.firstIndex(where: { $0.key.hasPrefix("-j") }) {
            var jobArgument = arguments[jobArgumentIndex]
            arguments.remove(at: jobArgumentIndex)
            files += parseFileList(jobArgument.value)
            jobArgument.value = nil
            arguments.insert(jobArgument, at: jobArgumentIndex)
        }

        if let threadsArgumentIndex = arguments.firstIndex(where: { $0.key == "-num-threads" }) {
            var threadsArgument = arguments[threadsArgumentIndex]
            arguments.remove(at: threadsArgumentIndex)
            let parts = threadsArgument.value?.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).map { String($0) } ?? []
            files += parseFileList(parts.last)
            threadsArgument.value = parts.first
            arguments.insert(threadsArgument, at: threadsArgumentIndex)
        }

        return SwiftcInvocation(arguments: arguments, files: files)
    }

    private func parseFileList(_ list: String?) -> [String] {
        return list?.components(separatedBy: " /").map { $0.hasPrefix("/") ? $0 : "/" + $0 } ?? []
    }

    private func splitArgumentPair(_ pair: String) -> (String, String?) {
        var key = ""
        var value: String?

        for c in pair.enumerated() {
            if c.element == "/" {
                // If an argument doesn't contain a space between the key and value then they must
                // remain joined.
                return (pair, nil)
            }

            if " " == c.element {
                var i = pair.index(pair.startIndex, offsetBy: c.offset)
                i = pair.index(i, offsetBy: 1)
                value = String(pair.suffix(from: i))
                break
            }

            key += String(c.element)
        }

        return (key, value)
    }

    private func sanitize(argValue value: String?) -> String? {
        return value?
            .replacingOccurrences(of: "\\ ", with: " ")
            .replacingOccurrences(of: "\\'", with: "'")
            .replacingOccurrences(of: "\\\"", with: "\"")
    }
}

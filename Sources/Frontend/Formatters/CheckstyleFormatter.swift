import Foundation
import PathKit
import Shared
import PeripheryKit

public final class CheckstyleFormatter: OutputFormatter {
    public static func make() -> Self {
        return self.init(logger: inject())
    }

    private let logger: Logger

    required public init(logger: Logger) {
        self.logger = logger
    }

    public func perform(_ declarations: [Declaration]) {
        let xml = [
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<checkstyle version=\"4.3\">",
            declarations
                .group(by: { ($0.location.file.string).escapedForXML() })
                .sorted(by: { $0.key < $1.key })
                .map(generateForFile).joined(),
            "\n</checkstyle>"
        ].joined()
        logger.info(xml, canQuiet: false)
    }

    // MARK: - Private

    private func generateForFile(_ file: String, declarations: [Declaration]) -> String {
        return [
            "\n\t<file name=\"", file, "\">\n",
            declarations.map(generateForDeclaration).joined(),
            "\t</file>"
        ].joined()
    }

    private func generateForDeclaration(_ declaration: Declaration) -> String {
        let line = declaration.location.line ?? 0
        let col = declaration.location.column ?? 0
        let reason = message(for: declaration)
        return [
            "\t\t<error line=\"\(line)\" ",
            "column=\"\(col)\" ",
            "severity=\"warning\" ",
            "message=\"", reason, "\"/>\n"
        ].joined()
    }

    private func message(for decl: Declaration) -> String {
        var message = ""

        if let name = decl.name {
            if let kind = decl.kind.displayName, let first_ = kind.first {
                let first = String(first_)
                message += "\(first.uppercased())\(kind.dropFirst()) "
            }

            message += "'\(name)'"

            if decl.analyzerHints.contains(.assignOnlyProperty) {
                message += " is assigned, but never used"
            } else {
                message += " is unused"
            }
        } else {
            message += "unused"
        }

        return message.escapedForXML()
    }
}

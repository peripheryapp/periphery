import Foundation
import Shared
import PeripheryKit

protocol OutputFormatter: AnyObject {
    static func make() -> Self
    func perform(_ declarations: [Declaration]) throws
}

extension OutputFormat {
    var formatter: OutputFormatter.Type {
        switch self {
        case .xcode:
            return XcodeFormatter.self
        case .csv:
            return CsvFormatter.self
        case .json:
            return JsonFormatter.self
        case .checkstyle:
            return CheckstyleFormatter.self
        }
    }
}

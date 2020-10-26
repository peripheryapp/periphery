import Foundation

final class Project {
    enum Kind {
        case xcode
    }

    static func build() throws -> Self {
        return try self.init(kind: .xcode)
    }

    let kind: Kind
    let driver: ProjectDriver

    init(kind: Kind) throws {
        self.kind = kind

        switch kind {
        case .xcode:
            self.driver = try XcodeProjectDriver.build()
        }
    }

    func index(graph: SourceGraph) throws {
        try driver.index(graph: graph)
    }
}

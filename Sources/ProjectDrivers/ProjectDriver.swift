import Foundation
import Indexer
import Logger
import SwiftIndexStore

public protocol ProjectDriver {
    func build() throws
    func plan(logger: ContextualLogger) throws -> IndexPlan
}

public extension ProjectDriver {
    func build() throws {}

    func plan(logger _: ContextualLogger) throws -> IndexPlan {
        IndexPlan(sourceFiles: [:])
    }
}

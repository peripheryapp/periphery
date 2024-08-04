import Foundation
import SwiftIndexStore
import Shared
import Indexer

public protocol ProjectDriver {
    func build() throws
    func plan(logger: ContextualLogger) throws -> IndexPlan
}

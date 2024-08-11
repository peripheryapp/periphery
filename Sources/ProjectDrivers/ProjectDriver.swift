import Foundation
import Indexer
import Shared
import SwiftIndexStore

public protocol ProjectDriver {
    func build() throws
    func plan(logger: ContextualLogger) throws -> IndexPlan
}

extension ProjectDriver {
  public func build() throws {}

  public func plan(logger: ContextualLogger) throws -> IndexPlan {
      IndexPlan(sourceFiles: [:])
  }
}

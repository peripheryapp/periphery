import Configuration
import Foundation
import Shared

protocol SourceGraphMutator: AnyObject {
    init(graph: SourceGraph, configuration: Configuration, swiftVersion: SwiftVersion)
    func mutate() throws
}

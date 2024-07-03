import Foundation
import Shared

protocol SourceGraphMutator: AnyObject {
    init(graph: SourceGraph, configuration: Configuration)
    func mutate() throws
}

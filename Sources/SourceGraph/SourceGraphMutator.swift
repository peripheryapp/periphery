import Foundation
import Configuration

protocol SourceGraphMutator: AnyObject {
    init(graph: SourceGraph, configuration: Configuration)
    func mutate() throws
}

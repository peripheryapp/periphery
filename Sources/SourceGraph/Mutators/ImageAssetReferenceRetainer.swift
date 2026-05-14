import Configuration
import Foundation
import Shared

final class ImageAssetReferenceRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        let referencedNames = Set(graph.imageAssetReferences.map(\.name))

        for imageAsset in graph.imageAssets where referencedNames.contains(imageAsset.name) {
            graph.markUsedImageAsset(imageAsset)
        }
    }
}

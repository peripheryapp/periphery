import Foundation
import SystemPackage
import Shared

public final class GenericProjectDriver {
    public static func build() throws -> Self {
        let configuration = Configuration.shared
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let sourceFiles = try configuration.fileTargetsPath
            .reduce(into: [FilePath: Set<IndexTarget>]()) { result, mapPath in
                guard mapPath.exists else {
                    throw PeripheryError.pathDoesNotExist(path: mapPath.string)
                }

                let data = try Data(contentsOf: mapPath.url)
                let map = try decoder
                    .decode(FileTargetMapContainer.self, from: data)
                    .fileTargets
                    .reduce(into: [FilePath: Set<IndexTarget>](), { (result, tuple) in
                        let (key, value) = tuple
                        let path = FilePath.makeAbsolute(key)

                        if !path.exists {
                            throw PeripheryError.pathDoesNotExist(path: path.string)
                        }

                        let indexTargets = value.mapSet { IndexTarget(name: $0) }
                        result[path] = indexTargets
                    })
                result.merge(map) { $0.union($1) }
            }

        return self.init(sourceFiles: sourceFiles, configuration: configuration)
    }

    private let sourceFiles: [FilePath: Set<IndexTarget>]
    private let configuration: Configuration

    init(sourceFiles: [FilePath: Set<IndexTarget>], configuration: Configuration) {
        self.sourceFiles = sourceFiles
        self.configuration = configuration
    }
}

extension GenericProjectDriver: ProjectDriver {
    public func build() throws {}

    public func index(graph: SourceGraph) throws {
        try SwiftIndexer(sourceFiles: sourceFiles, graph: graph, indexStorePaths: configuration.indexStorePath).perform()
        graph.indexingComplete()
    }
}

struct FileTargetMapContainer: Decodable {
    let fileTargets: [String: Set<String>]
}

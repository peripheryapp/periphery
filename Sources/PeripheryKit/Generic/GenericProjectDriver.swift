import Foundation
import SystemPackage
import Indexer
import Shared
import SourceGraph
import SwiftIndexStore

public final class GenericProjectDriver {
    private enum FileKind: String {
        case plist
    }

    public static func build() throws -> Self {
        let configuration = Configuration.shared
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let projectFiles = try configuration.fileTargetsPath
            .reduce(into: [FileKind: Set<FilePath>]()) { result, mapPath in
                guard mapPath.exists else {
                    throw PeripheryError.pathDoesNotExist(path: mapPath.string)
                }

                let data = try Data(contentsOf: mapPath.url)
                try decoder
                    .decode(FileTargetMapContainer.self, from: data)
                    .fileTargets
                    .forEach { key, value in
                        let path = FilePath.makeAbsolute(key)

                        if !path.exists {
                            throw PeripheryError.pathDoesNotExist(path: path.string)
                        }

                        guard let ext = path.extension, let fileKind = FileKind(rawValue: ext) else {
                            throw PeripheryError.unsupportedFileKind(path: path)
                        }

                        result[fileKind, default: []].insert(path)
                    }
            }

        return self.init(projectFiles: projectFiles, configuration: configuration)
    }

    private let projectFiles: [FileKind: Set<FilePath>]
    private let configuration: Configuration

    private init(projectFiles: [FileKind: Set<FilePath>], configuration: Configuration) {
        self.projectFiles = projectFiles
        self.configuration = configuration
    }
}

extension GenericProjectDriver: ProjectDriver {
    public func build() throws {}

    public func collect(logger: ContextualLogger) throws -> [SourceFile : [IndexUnit]] {
        try SourceFileCollector(
            indexStorePaths: configuration.indexStorePath,
            logger: logger
        ).collect()
    }

    public func index(
        sourceFiles: [SourceFile: [IndexUnit]],
        graph: SourceGraph,
        logger: ContextualLogger
    ) throws {
        try SwiftIndexer(
            sourceFiles: sourceFiles,
            graph: graph,
            logger: logger
        ).perform()

        if let plistFiles = projectFiles[.plist] {
            try InfoPlistIndexer(infoPlistFiles: plistFiles, graph: graph).perform()
        }

        graph.indexingComplete()
    }
}

struct FileTargetMapContainer: Decodable {
    let fileTargets: [String: Set<String>]
}

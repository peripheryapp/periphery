import Foundation
import SystemPackage
import Indexer
import Shared
import SourceGraph

public final class GenericProjectDriver {
    private enum FileKind: String {
        case swift
        case plist
    }

    public static func build() throws -> Self {
        let configuration = Configuration.shared
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let sourceFiles = try configuration.fileTargetsPath
            .reduce(into: [FileKind: [FilePath: Set<IndexTarget>]]()) { result, mapPath in
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

                        let indexTargets = value.mapSet { IndexTarget(name: $0) }
                        result[fileKind, default: [:]][path, default: []].formUnion(indexTargets)
                    }
            }

        return self.init(sourceFiles: sourceFiles, configuration: configuration)
    }

    private let sourceFiles: [FileKind: [FilePath: Set<IndexTarget>]]
    private let configuration: Configuration

    private init(sourceFiles: [FileKind: [FilePath: Set<IndexTarget>]], configuration: Configuration) {
        self.sourceFiles = sourceFiles
        self.configuration = configuration
    }
}

extension GenericProjectDriver: ProjectDriver {
    public func build() throws {}

    public func index(graph: SourceGraph) throws {
        if let swiftFiles = sourceFiles[.swift] {
            try SwiftIndexer(sourceFiles: swiftFiles, graph: graph, indexStorePaths: configuration.indexStorePath).perform()
        }

        if let plistFiles = sourceFiles[.plist] {
            try InfoPlistIndexer(infoPlistFiles: Set(plistFiles.keys), graph: graph).perform()
        }

        graph.indexingComplete()
    }
}

struct FileTargetMapContainer: Decodable {
    let fileTargets: [String: Set<String>]
}

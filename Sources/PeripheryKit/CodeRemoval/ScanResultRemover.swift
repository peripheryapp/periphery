import Foundation
import SwiftParser
import SwiftSyntax
import Shared
import SystemPackage
import SourceGraph

public final class ScanResultRemover {
    private let configuration: Configuration

    public init(configuration: Configuration = .shared) {
        self.configuration = configuration
    }

    public func remove(results: [ScanResult]) throws {
        let locationsByFile: [SourceFile: [(Location, [String], SyntaxRemover.Type)]] = results.reduce(into: .init()) { dict, result in
            let location = result.declaration.location
            let file = result.declaration.location.file

            switch result.annotation {
            case .unused, .assignOnlyProperty:
                dict[file, default: []].append((location, [], UnusedDeclarationSyntaxRemover.self))
            case .redundantPublicAccessibility:
                dict[file, default: []].append((location, [], PublicAccessibilitySyntaxRemover.self))
            case let .redundantProtocol(references, inherited):
                dict[file, default: []].append((location, [], RedundantProtocolSyntaxRemover.self))
                let replacements = inherited.sorted()

                for reference in references {
                    let location = reference.location
                    dict[location.file, default: []].append((location, replacements, RedundantProtocolSyntaxRemover.self))
                }
            }
        }

        for (file, locations) in locationsByFile {
            let source = try String(contentsOf: file.path.url)
            var syntax = Parser.parse(source: source)
            let locationConverter = SourceLocationConverter(fileName: file.path.string, tree: syntax)
            let locationBuilder = SourceLocationBuilder(file: file, locationConverter: locationConverter)
            let sortedLocations = locations.sorted { $0.0 > $1.0 }

            for (location, replacements, removerType) in sortedLocations {
                let remover = removerType.init(
                    resultLocation: location,
                    replacements: replacements,
                    locationBuilder: locationBuilder)
                syntax = remover.perform(syntax: syntax)
            }

            syntax = EmptyExtensionSyntaxRemover().perform(syntax: syntax)

            let isFileEmpty = EmptyFileVisitor().perform(syntax: syntax)

            var outputPath = file.path

            if let outputBasePath = configuration.removalOutputBasePath,
               let fileName = file.path.lastComponent {
                outputPath = outputBasePath.appending(fileName)
            }

            if isFileEmpty {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: outputPath.string) {
                    try fileManager.removeItem(at: outputPath.url)
                }
            } else {
                var output = ""
                syntax.write(to: &output)
                if output != source {
                    let outputData = output.data(using: .utf8)!
                    try outputData.write(to: outputPath.url, options: .atomic)
                }
            }
        }
    }
}

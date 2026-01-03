import Foundation
import SourceGraph
import SystemPackage

public struct IndexPlan {
    public let sourceFiles: [SourceFile: [IndexUnit]]
    public let plistPaths: Set<FilePath>
    public let xibPaths: Set<FilePath>
    public let xcDataModelPaths: Set<FilePath>
    public let xcMappingModelPaths: Set<FilePath>
    public let xcStringsPaths: Set<FilePath>

    public init(
        sourceFiles: [SourceFile: [IndexUnit]],
        plistPaths: Set<FilePath> = [],
        xibPaths: Set<FilePath> = [],
        xcDataModelPaths: Set<FilePath> = [],
        xcMappingModelPaths: Set<FilePath> = [],
        xcStringsPaths: Set<FilePath> = []
    ) {
        self.sourceFiles = sourceFiles
        self.plistPaths = plistPaths
        self.xibPaths = xibPaths
        self.xcDataModelPaths = xcDataModelPaths
        self.xcMappingModelPaths = xcMappingModelPaths
        self.xcStringsPaths = xcStringsPaths
    }
}

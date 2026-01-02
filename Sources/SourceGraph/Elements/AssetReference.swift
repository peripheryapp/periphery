import Foundation
import SystemPackage

public struct AssetReference: Hashable {
    public init(absoluteName: String, source: ProjectFileKind) {
        if let name = absoluteName.split(separator: ".").last {
            self.name = String(name)
        } else {
            name = absoluteName
        }
        self.source = source
        outlets = []
        actions = []
        runtimeAttributes = []
    }

    /// Initializer for Interface Builder references with outlet/action/attribute details.
    public init(
        absoluteName: String,
        source: ProjectFileKind,
        outlets: [String],
        actions: [String],
        runtimeAttributes: [String],
    ) {
        if let name = absoluteName.split(separator: ".").last {
            self.name = String(name)
        } else {
            name = absoluteName
        }
        self.source = source
        self.outlets = outlets
        self.actions = actions
        self.runtimeAttributes = runtimeAttributes
    }

    public let name: String
    public let source: ProjectFileKind

    /// Outlet property names referenced in Interface Builder (e.g., "button", "label").
    public let outlets: [String]

    /// Action selector names referenced in Interface Builder (e.g., "click:", "handleTap:").
    public let actions: [String]

    /// User-defined runtime attribute key paths (IBInspectable, e.g., "cornerRadius", "borderColor").
    public let runtimeAttributes: [String]
}

import Foundation

public protocol ProjectSetupGuide: SetupGuide {
    var projectKind: ProjectKind { get }
    var isSupported: Bool { get }
}

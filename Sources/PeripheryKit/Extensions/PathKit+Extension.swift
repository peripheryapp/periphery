import Foundation
import PathKit

public extension Path {
    func relativeTo(_ relativePath: Path) -> Path {
        let components = self.absolute().components
        let relativePathComponents = relativePath.absolute().components

        var commonPathComponents = [String]()
        for component in components {
            guard relativePathComponents.count > commonPathComponents.count else { break }
            guard relativePathComponents[commonPathComponents.count] == component else { break }
            commonPathComponents.append(component)
        }

        let relative = Array(repeating: "..", count: (relativePathComponents.count - commonPathComponents.count))
        let suffix = components.suffix(components.count - commonPathComponents.count)
        let path = Path(components: relative + suffix)
        return path
    }
}

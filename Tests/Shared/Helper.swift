import Foundation
import PathKit

public var ProjectRootPath: Path {
    let file = #file
    return Path(file) + "../../.."
}

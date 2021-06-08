import Foundation
import PathKit

var ProjectRootPath: Path {
    let file = #file
    return Path(file) + "../../.."
}

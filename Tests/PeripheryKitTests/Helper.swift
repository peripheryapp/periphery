import Foundation
import PathKit

var ProjectRootPath: Path {
    let file = #file
    return Path(file) + "../../.."
}

var PeripheryProjectPath: Path {
    return ProjectRootPath + "Periphery.xcodeproj"
}

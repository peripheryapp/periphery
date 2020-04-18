import Foundation
import PathKit

func PeripheryCachePath() throws -> Path {
    let url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    return Path(url.appendingPathComponent("com.github.peripheryapp").path)
}

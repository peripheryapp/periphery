import Foundation
import SystemPackage

public struct Constants {
    public static func cachePath() throws -> FilePath {
        let url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return FilePath(url.appendingPathComponent("com.github.peripheryapp").path)
    }
}

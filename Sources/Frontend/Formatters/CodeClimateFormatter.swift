import Foundation
import PeripheryKit

final class CodeClimateFormatter: OutputFormatter {
    
    func format(_ results: [PeripheryKit.ScanResult]) throws -> String {
        var jsonObject: [Any] = []

        for result in results {
            let lines: [AnyHashable: Any] = [
                "begin": result.declaration.location.line
            ]
            
            let location: [AnyHashable: Any] = [
                "path": result.declaration.location.file.path.url.relativePath,
                "lines": lines
            ]
            
            let description = describe(result, colored: false)
                .map { $0.1 }
                .joined(separator: ", ")
            
            let fingerprint: String
            if result.declaration.kind == .varParameter,
                let parentFingerprint = result.declaration.parent?.usrs.joined(separator: "."),
                let argumentName = result.declaration.name {
                // As function parameters do not have a mangled name that can be used for the fingerprint
                // we take the mangled name of the function and append the position
                fingerprint = "\(parentFingerprint)-\(argumentName)"
            } else {
                fingerprint = result.declaration.usrs.joined(separator: ".")
            }
            
            let object: [AnyHashable: Any] = [
                "description": description,
                "fingerprint": fingerprint,
                "severity": "major",
                "location": location
            ]
            
            jsonObject.append(object)
        }

        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        let json = String(data: data, encoding: .utf8)
        return json ?? ""
    }
    
}

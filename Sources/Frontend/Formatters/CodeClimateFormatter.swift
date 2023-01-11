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
            
            let object: [AnyHashable: Any] = [
                "description": description,
                "fingerprint": result.declaration.usrs.joined(separator: "."),
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

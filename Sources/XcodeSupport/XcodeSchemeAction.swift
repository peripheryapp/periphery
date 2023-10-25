import Foundation
import Shared

struct XcodeBuildAction: Decodable {
    let target: String
    let buildSettings: [String: String]

    func makeTargetTriple() throws -> String {
        let arch = buildSettings["CURRENT_ARCH"]
        let vendor = buildSettings["LLVM_TARGET_TRIPLE_VENDOR"]
        let osVersion = buildSettings["LLVM_TARGET_TRIPLE_OS_VERSION"]

        if let arch, let vendor, let osVersion {
            return "\(arch)-\(vendor)-\(osVersion)"
        } else {
            throw PeripheryError.invalidTargetTriple(
                target: target,
                arch: "ARCH = \(String(describing: arch))",
                vendor: "LLVM_TARGET_TRIPLE_VENDOR = \(String(describing: vendor))",
                osVersion: "LLVM_TARGET_TRIPLE_OS_VERSION = \(String(describing: osVersion))"
            )
        }
    }
}

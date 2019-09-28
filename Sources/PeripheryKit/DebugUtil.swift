// swiftlint:disable force_try

import Foundation

final class DebugUtil {
    static func prettyPrint(_ object: Any) {
        print(String(data: try! JSONSerialization.data(withJSONObject: object, options: .prettyPrinted), encoding: .utf8)!)
    }
}

import Foundation
import Commandant
import Result

public struct VersionCommand: CommandProtocol {
    public let verb = "version"
    public let function = "Display this version of Periphery"

    public init() {}

    public func run(_ options: ScanOptions) -> Result<(), PeripheryKitError> {
        print(PeripheryVersion)
        return .success(())
    }
}

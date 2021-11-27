import Foundation

public protocol InternalProtocolRefiningPublicProtocol_Refined {}
protocol InternalProtocolRefiningPublicProtocol: InternalProtocolRefiningPublicProtocol_Refined {}

public class InternalProtocolRefiningPublicProtocolRetainer {
    public init() {
        let _: InternalProtocolRefiningPublicProtocol? = nil
    }
}

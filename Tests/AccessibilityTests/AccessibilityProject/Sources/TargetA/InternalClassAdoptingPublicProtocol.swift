import Foundation

public protocol InternalClassAdoptingPublicProtocol_Protocol {}
class InternalClassAdoptingPublicProtocol: InternalClassAdoptingPublicProtocol_Protocol {
    public init() {}
}

public class InternalClassAdoptingPublicProtocolRetainer {
    public init() {
        let _: InternalClassAdoptingPublicProtocol? = nil
    }
}

import Foundation
import ExternalTarget

// Not referenced in MainTarget but retained due to retainObjcAccessible.
@objc public class PublicClassAdoptingExternalProtocolObjcAccessible: NSObject, ExternalProtocol {
    public override init() {}
    public func someExternalProtocolMethod() {}
}

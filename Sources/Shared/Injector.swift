import Foundation

private final class Injector {
    private static let singletonQueueSpecificKey = DispatchSpecificKey<Void>()
    private static var singletonQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "Injector.singletonQueue")
        queue.setSpecific(key: singletonQueueSpecificKey, value: ())
        return queue
    }()
    private static var singletons: [ObjectIdentifier: Singleton] = [:]

    fileprivate static func get<T: Singleton>(_ type: T.Type) -> T {
        var singleton: T?

        let block: () -> Void = {
            let identifier = ObjectIdentifier(type)

            if let instance = singletons[identifier] {
                singleton = (instance as! T) // swiftlint:disable:this force_cast
                return
            }

            singleton = type.make()
            singletons[identifier] = singleton
        }

        if DispatchQueue.getSpecific(key: singletonQueueSpecificKey) == nil {
            singletonQueue.sync(execute: block)
        } else {
            block()
        }

        return singleton!
    }

    fileprivate static func get<T: Injectable>(_ type: T.Type) -> T {
        return type.make()
    }
}

public protocol Injectable: AnyObject {
    static func make() -> Self
}

public protocol Singleton: Injectable {
    // Intentionally empty, used for specialization.
}

public func inject<T: Singleton>(_ type: T.Type? = nil) -> T {
    return Injector.get(T.self)
}

public func inject<T: Injectable>(_ type: T.Type? = nil) -> T {
    return Injector.get(T.self)
}

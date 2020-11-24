import Foundation

protocol FixtureProtocol110 {
    func sync(execute work: () -> Void) // Implementation provided by DispatchQueue, used
    func async(execute item: DispatchWorkItem) // Implementation provided by DispatchQueue, unused
    func customImplementedByExtensionUsed()
    func customImplementedByExtensionUnused()
}

extension FixtureProtocol110 {
    func customImplementedByExtensionUsed() {}
    func customImplementedByExtensionUnused() {}
}

extension DispatchQueue: FixtureProtocol110 {
    func sync(execute item: DispatchWorkItem) {}
    func async(execute item: DispatchWorkItem) {}
    func customImplementedByExtensionUsed() {}
    func customImplementedByExtensionUnused() {}
}

public class FixtureClass110Retainer {
    public func someFunc() {
        let queue: FixtureProtocol110 = DispatchQueue(label: "FixtureClass110")
        queue.sync {}
        queue.customImplementedByExtensionUsed()
        DispatchQueue.global().async {}
    }
}

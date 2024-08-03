import Foundation

protocol Fixture200 {}
protocol Fixture201 {}
typealias Fixture202 = Fixture200 & Fixture201

public struct Fixture203: Fixture202 {}

public struct Fixture204 {
    public func someFunc() {
        let x: Fixture202 = Fixture203()
        print(x)
    }
}

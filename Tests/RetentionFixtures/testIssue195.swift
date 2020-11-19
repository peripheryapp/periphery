import Foundation

class Issue195 {
    fileprivate enum Key {
        static let email = "Key.email"
    }
}

extension Issue195 {
    func someFunc() {
        print(Key.email)
    }
}

public class Issue195Retainer {
    public func someFunc() {
        print(Issue195().someFunc())
    }
}

import Foundation

class SyntaxFixture4 {
    func myFunc(param1: String, param2: String, param3: String?, param4: String?) {
        let _ = param1.description
        let _ = param2
        if let _ = param3 {}
        if let param4 {}
    }
}

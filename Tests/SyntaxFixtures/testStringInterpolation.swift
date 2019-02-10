import Foundation

class SyntaxFixture8 {
    func myFunc(param1: String, param2: String, param3: String, param4: String) {
        print("\(param1)")
        print("\(param2.description)")
        print("\(other(param3))")
        let x = param4 + "test"
        print(x)
    }

    func other(_ param: String) {
        print(param)
    }
}

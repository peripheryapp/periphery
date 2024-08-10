import Foundation

class SyntaxFixture5 {
    func myFunc(param1: String, param2: String) {
        // Check that the label isn't confused as an identifier.
        other(param2: param1)
    }

    func other(param2: String) {
        print(param2)
    }
}

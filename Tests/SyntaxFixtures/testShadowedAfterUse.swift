import Foundation

class SyntaxFixture6 {
    func myFunc(param: String) {
        print(param)
        let param = "shadowed"
        print(param)
    }
}

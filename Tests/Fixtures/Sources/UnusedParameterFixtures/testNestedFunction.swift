import Foundation

class SyntaxFixture19 {
    func myFunc(param: String) {
        func innerFunc() {
            print(param)
        }
    }
}

import Foundation

class SyntaxFixture16 {
    func myFunc(param: String) {
        myBlockFunc {
            let param = "test"
            print(param)
        }
    }

    func myBlockFunc(_ block: () -> Void) {
        block()
    }
}

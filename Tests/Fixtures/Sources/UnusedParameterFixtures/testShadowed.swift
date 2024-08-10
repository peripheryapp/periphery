import Foundation

class SyntaxFixture2 {
    func myFunc1(param: String) {
        let param = ""
        print(param)
    }

    func myFunc2(param: String) {
        let (other, param) = ("", "")
        print(param)
        print(other)
    }

    func myFunc3(param: String) {
        let other = "", param = ""
        print(param)
        print(other)
    }
}

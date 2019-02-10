import Foundation

class SyntaxFixture9Helper {
    init(param: String) {}
}

class SyntaxFixture9 {
    func myFunc(param1: String, param2: String) {
        print(SyntaxFixture9Helper(param: param1))
        print(SyntaxFixture9Helper(param: param2.description))
    }
}

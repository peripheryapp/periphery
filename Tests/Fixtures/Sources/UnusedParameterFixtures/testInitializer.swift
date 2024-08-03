import Foundation

class SyntaxFixture7Base {
    init(param: String) {}
}

class SyntaxFixture7: SyntaxFixture7Base {
    required init(param1: String, param2: String) {
        super.init(param: param1)
    }
}

import Foundation

class SyntaxFixture18 {
    func myFunc<A: Hashable, B, C>(param1: A.Type, param2: B.Type? = nil, param3: C.Type!) {}
}

import Foundation

class SyntaxFixtureNestedAnalyzer {
    func outer(outerParam: String) {
        func innerFunc(param: String) {
            print(outerParam)
        }

        innerFunc(param: "value")
    }
}

import Foundation

class SyntaxFixture12 {
    func myFunc(param1: String,
                param2: String,
                // Some comment.
                param3: String,
                _ param4: String,
                with param5: String,
                _ // Another comment.
                    param6: String
                ) {}
}

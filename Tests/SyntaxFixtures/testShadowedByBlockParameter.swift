import Foundation

class SyntaxFixture14 {
    func myFunc(param1: String, param2: String, param3: String, param4: String) {
        // Shadowed
        myBlockFunc1 { param1 in print(param1) }

        // Shadowed
        myBlockFunc1 { unused in
            myBlockFunc1 { param1 in
                print(param1)
            }
        }

        // Used
        myBlockFunc1 { unused in
            myBlockFunc1 { unused in
                print(param3)
            }
        }

        // Unused
        myBlockFunc2({ param4 in
            print(param4)
        }, param4)
    }

    func myBlockFunc1(_ block: (String) -> Void) {}
    func myBlockFunc2(_ block: (String) -> Void, _ param: String) {}
}

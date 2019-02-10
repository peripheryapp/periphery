import Foundation

class FixtureClass9 {
    var forever = true

    func recursive() {
        if forever {
            recursive()
        }
    }
}

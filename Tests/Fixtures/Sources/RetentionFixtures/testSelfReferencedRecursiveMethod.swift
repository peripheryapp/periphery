import Foundation

public class FixtureClass9 {
    var flag = true

    func recursive() {
        if flag {
            recursive()
        }
    }
}

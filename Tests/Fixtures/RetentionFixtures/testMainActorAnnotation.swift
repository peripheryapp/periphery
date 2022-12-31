import Foundation

@MainActor class FixtureClass132 {
    let text = ""
}

public class FixtureClass133 {
    @MainActor let main = FixtureClass132()

    @MainActor public func retain() {
        _ = main.text
    }
}

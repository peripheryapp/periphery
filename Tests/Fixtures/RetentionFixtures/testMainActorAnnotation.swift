import Foundation

@MainActor class FixtureClass132 {
    init(value: Int) {}
    let text = ""
}

public class FixtureClass133 {
    @MainActor let main = FixtureClass132(value: 1)

    @MainActor public func retain() {
        _ = main.text
    }
}

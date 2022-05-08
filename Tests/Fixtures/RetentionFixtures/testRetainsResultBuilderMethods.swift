import Foundation

@resultBuilder
class FixtureClass130 {
    typealias Component = [Int]
    typealias Expression = Int

    static func buildExpression(_ element: Expression) -> Component {
        [element]
    }

    static func buildOptional(_ component: Component?) -> Component {
        guard let component = component else { return [] }
        return component
    }

    static func buildEither(first component: Component) -> Component {
        component
    }

    static func buildEither(second component: Component) -> Component {
        component
    }

    static func buildArray(_ components: [Component]) -> Component {
        Array(components.joined())
    }

    static func buildBlock(_ components: Component...) -> Component {
        Array(components.joined())
    }
}

public class FixtureClass130Retainer {
    public func build() {
        _ = buildNonPublic {}
    }

    func buildNonPublic(@FixtureClass130 _ content: () -> [Int]) -> [Int] {
        content()
    }
}

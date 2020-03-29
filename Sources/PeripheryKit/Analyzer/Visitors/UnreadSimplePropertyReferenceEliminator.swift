import Foundation

// Aggressive Mode Only.
// Removes all references to the setter accessor of simple properties.
// Properties that aren't referenced via their getter will thus be identified as unused.
final class UnreadSimplePropertyReferenceEliminator: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph, configuration: inject())
    }

    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func transformToGetterUsr(fromMangledSetterUsr usr: String) -> String {
        var usr = usr
        assert(usr.last == "s")
        usr.removeLast()
        usr.append("g")
        return usr
    }

    func transformToPropertyUsr(fromMangledSetterUsr usr: String) -> String {
        var usr = usr
        assert(usr.last == "s")
        usr.removeLast()
        usr.append("p")
        return usr
    }


    func visit() {
        guard configuration.aggressive else { return }

        let setters = graph.declarations(ofKind: .functionAccessorSetter)

        for setter in setters {
            let references = graph.references(to: setter)

            for reference in references {
                if configuration.useIndexStore {
                    guard let caller = reference.parent else { continue }
                    let getterUsr = transformToGetterUsr(fromMangledSetterUsr: reference.usr)
                    let propertyUsr = transformToPropertyUsr(fromMangledSetterUsr: reference.usr)

                    guard let property = graph.declaration(withUsr: propertyUsr),
                        let propertyReference = caller.references.first(where: { $0.usr == propertyUsr }),
                        !property.isComplexProperty else { continue }

                    let hasGetterReference = caller.references.contains(where: { $0.kind == .functionAccessorGetter && $0.usr == getterUsr })
                    if !hasGetterReference {
                        graph.remove(propertyReference)
                        property.analyzerHints.append(.unreadProperty)
                        property.analyzerHints.append(.aggressive)
                    }
                } else {
                    // Parent should be a reference to a simple property.
                    guard let propertyReference = reference.parent as? Reference,
                        let property = graph.declaration(withUsr: propertyReference.usr),
                        !property.isComplexProperty else { continue }
                    // If the property reference has no other descendent references we can remove it.
                    if propertyReference.references == [reference] {
                        graph.remove(propertyReference)
                        property.analyzerHints.append(.unreadProperty)
                        property.analyzerHints.append(.aggressive)
                    }
                }
            }
        }
    }
}

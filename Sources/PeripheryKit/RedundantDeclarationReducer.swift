import Foundation

class RedundantDeclarationReducer {
    private let declarations: Set<Declaration>

    init(declarations: Set<Declaration>) {
        self.declarations = declarations
    }

    func reduce() -> Set<Declaration> {
        var reducedDeclarations = removeConstructors(declarations)
        reducedDeclarations = removeAccessors(reducedDeclarations)
        return reducedDeclarations
    }

    // MARK: - Private

    private func removeConstructors(_ declarations: Set<Declaration>) -> Set<Declaration> {
        return declarations.filter { !($0.kind == .functionConstructor && $0.name == nil) }
    }

    private func removeAccessors(_ declarations: Set<Declaration>) -> Set<Declaration> {
        return declarations.filter { !$0.kind.isAccessorKind }
    }
}

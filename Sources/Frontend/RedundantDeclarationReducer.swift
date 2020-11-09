import Foundation
import PeripheryKit

final class RedundantDeclarationReducer {
    private let declarations: Set<Declaration>

    init(declarations: Set<Declaration>) {
        self.declarations = declarations
    }

    func reduce() -> Set<Declaration> {
        removeAccessors(declarations)
    }

    // MARK: - Private

    private func removeAccessors(_ declarations: Set<Declaration>) -> Set<Declaration> {
        return declarations.filter { !$0.kind.isAccessorKind }
    }
}

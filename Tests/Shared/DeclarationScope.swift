@testable import SourceGraph

enum DeclarationScope {
    case declaration(Declaration)
    case module(String)
}

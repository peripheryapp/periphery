import Foundation
import PathKit
import SwiftSyntax

protocol Item: AnyObject {
    var items: [Item] { get }
}

final class Function: Item {
    let name: String
    let fullName: String
    let location: SourceLocation
    let items: [Item]
    let parameters: [Parameter]
    let genericParameters: [String]

    init(name: String, fullName: String, location: SourceLocation, items: [Item], parameters: [Parameter], genericParameters: [String]) {
        self.name = name
        self.fullName = fullName
        self.location = location
        self.items = items
        self.parameters = parameters
        self.genericParameters = genericParameters
    }
}

final class Parameter: Item, Hashable {
    static func == (lhs: Parameter, rhs: Parameter) -> Bool {
        return lhs.location == rhs.location
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(location)
    }

    let firstName: String?
    let secondName: String?
    let metatype: String?
    let location: SourceLocation
    let items: [Item] = []
    var function: Function?

    var name: String {
        return secondName ?? firstName ?? ""
    }

    var declaration: Declaration {
        let functionName = function?.fullName ?? "func()"
        let locationSha = location.description.sha1.prefix(10)
        let usr = "\(locationSha)-\(functionName)-\(name)"
        let decl = Declaration(kind: .varParameter, usr: usr, location: location)
        decl.name = name
        return decl
    }

    init(firstName: String?, secondName: String?, metatype: String?, location: SourceLocation) {
        self.firstName = firstName
        self.secondName = secondName
        self.metatype = metatype
        self.location = location
    }
}

final class Variable: Item {
    let names: [String]
    let items: [Item]

    init(names: [String], items: [Item]) {
        self.names = names
        self.items = items
    }
}

final class Closure: Item {
    let params: [String]
    let items: [Item]

    init(params: [String], items: [Item]) {
        self.params = params
        self.items = items
    }
}

final class Identifier: Item {
    let name: String
    let items: [Item] = []

    init(name: String) {
        self.name = name
    }
}

final class GenericItem: Item {
    let node: Syntax
    let items: [Item]

    init(node: Syntax, items: [Item]) {
        self.node = node
        self.items = items
    }
}

final class UnusedParameterParser {
    private let syntax: SourceFileSyntax
    private let parseProtocols: Bool
    private let sourceFile: SourceFile
    private let locationConverter: SourceLocationConverter

    static func parse(file: Path, parseProtocols: Bool) throws -> [Function] {
        let syntax = try SyntaxParser.parse(file.url)
        let sourceFile = SourceFile(path: file)
        let locationConverter = SourceLocationConverter(file: file.string, tree: syntax)
        let parser = self.init(syntax: syntax,
                               parseProtocols: parseProtocols,
                               sourceFile: sourceFile,
                               locationConverter: locationConverter)
        return try parser.parse()
    }

    private init(syntax: SourceFileSyntax, parseProtocols: Bool, sourceFile: SourceFile, locationConverter: SourceLocationConverter) {
        self.syntax = syntax
        self.parseProtocols = parseProtocols
        self.sourceFile = sourceFile
        self.locationConverter = locationConverter
    }

    func parse() throws -> [Function] {
        return parse(node: syntax, collecting: Function.self)
    }

    // MARK: - Private

    private func parse<T: Item>(node: SyntaxProtocol, collecting: T.Type) -> [T] {
        return parse(children: node.children, collecting: collecting)
    }

    private func parse<T: Item>(children: SyntaxChildren, collecting: T.Type) -> [T] {
        return parse(nodes: Array(children), collecting: collecting)
    }

    private func parse<T: Item>(nodes: [Syntax], collecting: T.Type) -> [T] {
        let collector = Collector<T>()
        nodes.forEach { _ = parse(node: $0, collector) }
        return collector.collection
    }

    private func parse<T>(node anyNode: SyntaxProtocol?, _ collector: Collector<T>? = nil) -> Item? {
        guard let node = anyNode?._syntaxNode else { return nil }

        let parsed: Item?

        if let node = node.as(MemberAccessExprSyntax.self) {
            // It's not possible for the member itself to be a reference to a parameter,
            // however the base expression may be.
            parsed = parse(node: node.base, collector)
        } else if let node = node.as(CodeBlockItemSyntax.self) {
            parsed = parse(node: node.item, collector)
        } else if let node = node.as(ParameterClauseSyntax.self) {
            parsed = parse(node: node.parameterList, collector)
        } else if let node = node.as(VariableDeclSyntax.self) {
            parsed = parse(variableDecl: node, collector)
        } else if let node = node.as(ClosureExprSyntax.self) {
            parsed = parse(closureExpr: node, collector)
        } else if let node = node.as(IdentifierExprSyntax.self) {
            parsed = parse(identifierExpr: node)
        } else if let node = node.as(FunctionParameterSyntax.self) {
            parsed = parse(functionParameter: node)
        } else if let node = node.as(FunctionDeclSyntax.self) {
            parsed = parse(functionDecl: node, collector)
        } else if let node = node.as(InitializerDeclSyntax.self) {
            parsed = parse(initializerDecl: node, collector)
        } else {
            let items = node.children.compactMap { parse(node: $0, collector) }
            if items.count > 0 {
                parsed = GenericItem(node: node, items: items)
            } else {
                parsed = nil
            }
        }

        if let collector = collector, let parsed = parsed {
            collector.add(parsed)
        }

        return parsed
    }

    private func parse(functionParameter syntax: FunctionParameterSyntax) -> Item {
        var metatype: String?

        if let optionalType = syntax.type?.as(OptionalTypeSyntax.self) {
            if let metatypeSyntax = optionalType.children.mapFirst({ $0.as(MetatypeTypeSyntax.self) }) {
                metatype = metatypeSyntax.description
            }
        } else if let optionalType = syntax.type?.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            if let metatypeSyntax = optionalType.children.mapFirst({ $0.as(MetatypeTypeSyntax.self) }) {
                metatype = metatypeSyntax.description
            }
        } else if let metatypeSyntax = syntax.type?.as(MetatypeTypeSyntax.self) {
            metatype = metatypeSyntax.description
        }

        return Parameter(firstName: syntax.firstName?.text,
                         secondName: syntax.secondName?.text,
                         metatype: metatype,
                         location: sourceLocation(of: syntax.position))
    }

    private func parse<T>(closureExpr syntax: ClosureExprSyntax, _ collector: Collector<T>?) -> Closure? {
        let signature = syntax.children.mapFirst { $0.as(ClosureSignatureSyntax.self) }
        let rawParams = signature?.input?.children.compactMap { $0.as(ClosureParamSyntax.self) }
        let params = rawParams?.map { $0.name.text } ?? []
        let items = syntax.statements.compactMap { parse(node: $0.item, collector) }
        return Closure(params: params, items: items)
    }

    private func parse<T>(variableDecl syntax: VariableDeclSyntax, _ collector: Collector<T>?) -> Variable {
        let bindings = syntax.bindings

        let names = bindings.flatMap { binding -> [String] in
            let pattern = binding.pattern

            if let pattern = pattern.as(IdentifierPatternSyntax.self) {
                return [pattern.identifier.text]
            } else if let pattern = pattern.as(TuplePatternSyntax.self) {
                return pattern.elements.compactMap {
                    let token = $0.pattern.children.mapFirst { $0.as(TokenSyntax.self) }
                    return token?.text
                }
            } else {
                return []
            }
        }

        let items = bindings.flatMap {
            return $0.initializer?.children.compactMap { parse(node: $0, collector) } ?? []
        }

        return Variable(names: names, items: items)
    }

    private func parse(identifierExpr syntax: IdentifierExprSyntax) -> Item {
        return Identifier(name: syntax.identifier.text)
    }

    private func parse<T>(functionDecl syntax: FunctionDeclSyntax, _ collector: Collector<T>?) -> Item? {
        return build(function: syntax.signature,
                     genericParams: syntax.genericParameterClause,
                     body: syntax.body,
                     named: syntax.identifier.text,
                     position: syntax.identifier.position,
                     collector)
    }

    private func parse<T>(initializerDecl syntax: InitializerDeclSyntax, _ collector: Collector<T>?) -> Item? {
        // syntax.initKeyword.position is incorrect, try to find the correct position.
        var position = syntax.initKeyword.position

        if let leftBracket = syntax.genericParameterClause?.leftAngleBracket {
            position = AbsolutePosition(utf8Offset: leftBracket.position.utf8Offset - 4)
        } else {
            let leftParen = syntax.parameters.leftParen
            position = AbsolutePosition(utf8Offset: leftParen.position.utf8Offset - 4)
        }

        return build(function: syntax.parameters,
                     genericParams: syntax.genericParameterClause,
                     body: syntax.body,
                     named: "init",
                     position: position,
                     collector)
    }

    private func build<T>(function syntax: SyntaxProtocol, genericParams: GenericParameterClauseSyntax?, body: CodeBlockSyntax?, named name: String, position: AbsolutePosition, _ collector: Collector<T>?) -> Function? {
        if body == nil && !parseProtocols {
            // Function has no body, must be a protocol declaration.
            return nil
        }

        // TODO: It'd be nice to avoid building this function if it has no params, however
        // Swift supports nested functions, so it's possible this function captures a param
        // from an outer function.

        let params = parse(children: syntax.children, collecting: Parameter.self)
        let items = parse(node: body, collector)?.items ?? []
        let fullName = buildFullName(for: name, with: params)
        let genericParamNames = genericParams?.genericParameterList.compactMap { $0.name.text } ?? []

        let function = Function(
            name: name,
            fullName: fullName,
            location: sourceLocation(of: position),
            items: items,
            parameters: params,
            genericParameters: genericParamNames)

        params.forEach { $0.function = function }
        return function
    }

    private func buildFullName(for function: String, with params: [Parameter]) -> String {
        let strParams = params.map {
            [$0.firstName, $0.secondName].compactMap { $0 }.joined(separator: " ")
        }.joined(separator: ":")
        return "\(function)(\(strParams):)"
    }

    private func sourceLocation(of position: AbsolutePosition) -> SourceLocation {
        let location = locationConverter.location(for: position)
        return SourceLocation(file: sourceFile,
                              line: Int64(location.line!),
                              column: Int64(location.column!),
                              offset: Int64(position.utf8Offset))
    }
}

private final class Collector<T> {
    private(set) var collection: [T] = []

    func add(_ item: Item) {
        if let item = item as? T {
            collection.append(item)
        }
    }
}

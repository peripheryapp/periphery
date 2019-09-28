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
        let locationSha = location.description.sha1().prefix(10)
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
    let kind: String
    let items: [Item]

    init(kind: String, items: [Item]) {
        self.kind = kind
        self.items = items
    }
}

final class UnusedParamParser {
    private let file: Path
    private let parseProtocols: Bool

    init(file: Path, parseProtocols: Bool) {
        self.file = file
        self.parseProtocols = parseProtocols
    }

    func parse() throws -> [Function] {
        let sourceKit = SourceKit(arguments: [])
        let syntaxTreeResponse = try sourceKit.syntaxTree(file: file)
        let key = SourceKit.Key.serializedSyntaxTree.rawValue

        guard let syntaxTreeJson = syntaxTreeResponse[key] as? String
            else { return [] }

        return try parse(syntaxTreeJson: syntaxTreeJson)
    }

    func parse(syntaxTreeJson: String) throws -> [Function] {
        guard let syntaxTreeData = syntaxTreeJson.data(using: .utf8)
            else { return [] }

        let deserializer = SyntaxTreeDeserializer()
        let syntax = try deserializer.deserialize(syntaxTreeData, serializationFormat: .json)
        return parse(item: syntax, collecting: Function.self)
    }

    // MARK: - Private

    private func parse<T: Item>(item: Syntax, collecting: T.Type) -> [T] {
        return parse(items: [item], collecting: collecting)
    }

    private func parse<T: Item>(item: SyntaxChildren, collecting: T.Type) -> [T] {
        let items = item.map { $0 }
        return parse(items: items, collecting: collecting)
    }

    private func parse<T: Item>(items: [Syntax], collecting: T.Type) -> [T] {
        let collector = Collector<T>()
        items.forEach { _ = parse(item: $0, collector) }
        return collector.collection
    }

    private func parse<T>(item: Syntax?, _ collector: Collector<T>? = nil) -> Item? {
        guard let item = item else { return nil }

//        inspect(item)

        let parsed: Item?

        switch item {
        case let item as MemberAccessExprSyntax:
            // It's not possible for the member itself to be a reference to a parameter,
            // however the base expression may be.
            parsed = parse(item: item.base, collector)
        case let item as CodeBlockItemSyntax:
            parsed = parse(item: item.item, collector)
        case let item as FunctionCallArgumentSyntax:
            parsed = parse(item: item.expression, collector)
        case let item as ParameterClauseSyntax:
            parsed = parse(item: item.parameterList, collector)
        case let item as VariableDeclSyntax:
            parsed = parse(variableDecl: item, collector)
        case let item as ClosureExprSyntax:
            parsed = parse(closureExpr: item, collector)
        case let item as IdentifierExprSyntax:
            parsed = parse(identifierExpr: item)
        case let item as FunctionParameterSyntax:
            parsed = parse(functionParameter: item)
        case let item as FunctionDeclSyntax:
            parsed = parse(functionDecl: item, collector)
        case let item as InitializerDeclSyntax:
            parsed = parse(initializerDecl: item, collector)
        default:
            if item.numberOfChildren > 0 {
                let items = item.children.compactMap { parse(item: $0, collector) }
                let kind = String(describing: type(of: item))
                parsed = GenericItem(kind: kind, items: items)
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

        if let optionalType = syntax.type as? OptionalTypeSyntax {
            if let metatypeSyntax = optionalType.children.mapFirst({ $0 as? MetatypeTypeSyntax }) {
                metatype = metatypeSyntax.description
            }
        } else if let optionalType = syntax.type as? ImplicitlyUnwrappedOptionalTypeSyntax {
            if let metatypeSyntax = optionalType.children.mapFirst({ $0 as? MetatypeTypeSyntax }) {
                metatype = metatypeSyntax.description
            }
        } else if let metatypeSyntax = syntax.type as? MetatypeTypeSyntax {
            metatype = metatypeSyntax.description
        }

        return Parameter(firstName: syntax.firstName?.text,
                         secondName: syntax.secondName?.text,
                         metatype: metatype,
                         location: sourceLocation(of: syntax.position))
    }

    private func parse<T>(closureExpr syntax: ClosureExprSyntax, _ collector: Collector<T>?) -> Closure? {
        let signature = syntax.children.mapFirst { $0 as? ClosureSignatureSyntax }
        let rawParams = signature?.input?.children.compactMap { $0 as? ClosureParamSyntax }
        let params = rawParams?.map { $0.name.text } ?? []
        let items = syntax.statements.compactMap { parse(item: $0, collector) }
        return Closure(params: params, items: items)
    }

    private func parse<T>(variableDecl syntax: VariableDeclSyntax, _ collector: Collector<T>?) -> Variable {
        let bindings = syntax.bindings

        let names = bindings.flatMap { binding -> [String] in
            let pattern = binding.pattern

            switch pattern {
            case let pattern as IdentifierPatternSyntax:
                return [pattern.identifier.text]
            case let pattern as TuplePatternSyntax:
                return pattern.elements.compactMap {
                    let token = $0.pattern.children.mapFirst { $0 as? TokenSyntax }
                    return token?.text
                }
            default:
                return []
            }
        }

        let items = bindings.flatMap {
            return $0.initializer?.children.compactMap { parse(item: $0, collector) } ?? []
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
            // leftBracket offset is incorrect by +1
            position = AbsolutePosition(line: leftBracket.position.line,
                                        column: leftBracket.position.column - 4,
                                        utf8Offset: leftBracket.position.utf8Offset - 5)
        } else {
            let leftParen = syntax.parameters.leftParen
            position = AbsolutePosition(line: leftParen.position.line,
                                        column: leftParen.position.column - 4,
                                        utf8Offset: leftParen.position.utf8Offset - 4)
        }

        return build(function: syntax.parameters,
                     genericParams: syntax.genericParameterClause,
                     body: syntax.body,
                     named: "init",
                     position: position,
                     collector)
    }

    private func build<T>(function syntax: Syntax, genericParams: GenericParameterClauseSyntax?, body: Syntax?, named name: String, position: AbsolutePosition, _ collector: Collector<T>?) -> Function? {
        if body == nil && !parseProtocols {
            // Function has no body, must be a protocol declaration.
            return nil
        }

        // TODO: It'd be nice to avoid building this function if it has no params, however
        // Swift supports nested functions, so it's possible this function captures a param
        // from an outer function.

        let params = parse(item: syntax.children, collecting: Parameter.self)
        let items = parse(item: body, collector)?.items ?? []
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

    private func inspect(_ syntax: Syntax?) {
        guard let syntax = syntax else { return }

        syntax.children.forEach {
            print("--------------------------------")
            print(type(of: $0))
            print($0)
        }
    }

    private func buildFullName(for function: String, with params: [Parameter]) -> String {
        let strParams = params.map {
            [$0.firstName, $0.secondName].compactMap { $0 }.joined(separator: " ")
        }.joined(separator: ":")
        return "\(function)(\(strParams):)"
    }

    private func sourceLocation(of position: AbsolutePosition) -> SourceLocation {
        return SourceLocation(file: SourceFile(path: file),
                              line: Int64(position.line),
                              column: Int64(position.column),
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

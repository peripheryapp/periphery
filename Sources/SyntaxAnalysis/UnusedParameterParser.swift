import Foundation
import SourceGraph
import SwiftParser
import SwiftSyntax
import SystemPackage

public protocol Item: AnyObject {
    var items: [Item] { get }
}

public final class Function: Item, Hashable {
    public static func == (lhs: Function, rhs: Function) -> Bool {
        lhs.location == rhs.location
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(location)
    }

    public let name: String
    public let fullName: String
    public let location: Location
    public let items: [Item]
    public let parameters: [Parameter]
    public let genericParameters: [String]
    public let attributes: [String]

    init(
        name: String,
        fullName: String,
        location: Location,
        items: [Item],
        parameters: [Parameter],
        genericParameters: [String],
        attributes: [String]
    ) {
        self.name = name
        self.fullName = fullName
        self.location = location
        self.items = items
        self.parameters = parameters
        self.genericParameters = genericParameters
        self.attributes = attributes
    }
}

public final class Parameter: Item, Hashable {
    public static func == (lhs: Parameter, rhs: Parameter) -> Bool {
        lhs.location == rhs.location
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(location)
    }

    let firstName: String?
    let secondName: String?
    let metatype: String?
    let location: Location
    public let items: [Item] = []
    var function: Function?

    public var name: String {
        secondName ?? firstName ?? ""
    }

    public func makeDeclaration(withParent parent: Declaration) -> Declaration {
        let functionName = function?.fullName ?? "func()"
        let parentUsrs = parent.usrs.joined(separator: "-")
        let usr = "param-\(name)-\(functionName)-\(parentUsrs)"
        let decl = Declaration(kind: .varParameter, usrs: [usr], location: location)
        decl.name = name
        decl.parent = parent
        return decl
    }

    init(firstName: String?, secondName: String?, metatype: String?, location: Location) {
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

struct UnusedParameterParser {
    private let syntax: SourceFileSyntax
    private let parseProtocols: Bool
    private let file: SourceFile
    private let locationConverter: SourceLocationConverter

    static func parse(
        file: SourceFile,
        syntax: SourceFileSyntax,
        locationConverter: SourceLocationConverter,
        parseProtocols: Bool
    ) -> [Function] {
        let parser = self.init(
            file: file,
            syntax: syntax,
            locationConverter: locationConverter,
            parseProtocols: parseProtocols
        )
        return parser.parse()
    }

    static func parse(file: SourceFile, parseProtocols: Bool) throws -> [Function] {
        let source = try String(contentsOf: file.path.url)
        let syntax = Parser.parse(source: source)
        let locationConverter = SourceLocationConverter(fileName: file.path.string, tree: syntax)
        return parse(
            file: file,
            syntax: syntax,
            locationConverter: locationConverter,
            parseProtocols: parseProtocols
        )
    }

    private init(file: SourceFile, syntax: SourceFileSyntax, locationConverter: SourceLocationConverter, parseProtocols: Bool) {
        self.file = file
        self.syntax = syntax
        self.locationConverter = locationConverter
        self.parseProtocols = parseProtocols
    }

    func parse() -> [Function] {
        parse(node: syntax, collecting: Function.self)
    }

    // MARK: - Private

    private func parse<T: Item>(node: SyntaxProtocol, collecting: T.Type) -> [T] {
        parse(children: node.children(viewMode: .sourceAccurate), collecting: collecting)
    }

    private func parse<T: Item>(children: SyntaxChildren, collecting: T.Type) -> [T] {
        parse(nodes: Array(children), collecting: collecting)
    }

    private func parse<T: Item>(nodes: [Syntax], collecting _: T.Type) -> [T] {
        let collector = Collector<T>()
        nodes.forEach { _ = parse(node: $0, collector) }
        return collector.collection
    }

    private func parse(node anyNode: SyntaxProtocol?, _ collector: Collector<some Any>? = nil) -> Item? {
        guard let node = anyNode?._syntaxNode else { return nil }

        let parsed: Item? = if let node = node.as(MemberAccessExprSyntax.self) {
            // It's not possible for the member itself to be a reference to a parameter,
            // however the base expression may be.
            parse(node: node.base, collector)
        } else if let node = node.as(CodeBlockItemSyntax.self) {
            parse(node: node.item, collector)
        } else if let node = node.as(FunctionParameterClauseSyntax.self) {
            parse(node: node.parameters, collector)
        } else if let node = node.as(VariableDeclSyntax.self) {
            parse(variableDecl: node, collector)
        } else if let node = node.as(ClosureExprSyntax.self) {
            parse(closureExpr: node, collector)
        } else if let node = node.as(DeclReferenceExprSyntax.self) {
            parse(identifier: node.baseName)
        } else if let node = node.as(FunctionParameterSyntax.self) {
            parse(functionParameter: node)
        } else if let node = node.as(FunctionDeclSyntax.self) {
            parse(functionDecl: node, collector)
        } else if let node = node.as(InitializerDeclSyntax.self) {
            parse(initializerDecl: node, collector)
        } else if let optBindingCondition = node.as(OptionalBindingConditionSyntax.self) {
            if optBindingCondition.initializer == nil,
               let pattern = optBindingCondition.pattern.as(IdentifierPatternSyntax.self),
               let parentStmt = optBindingCondition.parent?.parent?.parent,
               parentStmt.is(IfExprSyntax.self) || parentStmt.is(GuardStmtSyntax.self)
            {
                // Handle `let x {}` syntax.
                parse(identifier: pattern.identifier)
            } else {
                parse(childrenFrom: node, collector)
            }
        } else {
            parse(childrenFrom: node, collector)
        }

        if let collector, let parsed {
            collector.add(parsed)
        }

        return parsed
    }

    private func parse(childrenFrom node: Syntax, _ collector: Collector<some Any>?) -> Item? {
        let items = node.children(viewMode: .sourceAccurate).compactMap { parse(node: $0, collector) }
        if !items.isEmpty {
            return GenericItem(node: node, items: items)
        }
        return nil
    }

    private func parse(functionParameter syntax: FunctionParameterSyntax) -> Item {
        var metatype: String?

        if let optionalType = syntax.type.as(OptionalTypeSyntax.self) {
            if let metatypeSyntax = optionalType.children(viewMode: .sourceAccurate).mapFirst({ $0.as(MetatypeTypeSyntax.self) }) {
                metatype = metatypeSyntax.description
            }
        } else if let optionalType = syntax.type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            if let metatypeSyntax = optionalType.children(viewMode: .sourceAccurate).mapFirst({ $0.as(MetatypeTypeSyntax.self) }) {
                metatype = metatypeSyntax.description
            }
        } else if let metatypeSyntax = syntax.type.as(MetatypeTypeSyntax.self) {
            metatype = metatypeSyntax.description
        }

        let positionSyntax: SyntaxProtocol = syntax.secondName ?? syntax.firstName
        let location = sourceLocation(of: positionSyntax.positionAfterSkippingLeadingTrivia)

        return Parameter(firstName: syntax.firstName.text,
                         secondName: syntax.secondName?.text,
                         metatype: metatype,
                         location: location)
    }

    private func parse(closureExpr syntax: ClosureExprSyntax, _ collector: Collector<some Any>?) -> Closure? {
        let signature = syntax.children(viewMode: .sourceAccurate).mapFirst { $0.as(ClosureSignatureSyntax.self) }
        let rawParams = signature?.parameterClause?.children(viewMode: .sourceAccurate).compactMap { $0.as(ClosureShorthandParameterSyntax.self) }
        let params = rawParams?.map(\.name.text) ?? []
        let items = syntax.statements.compactMap { parse(node: $0.item, collector) }
        return Closure(params: params, items: items)
    }

    private func parse(variableDecl syntax: VariableDeclSyntax, _ collector: Collector<some Any>?) -> Variable {
        let bindings = syntax.bindings

        let names = bindings.flatMap { binding -> [String] in
            let pattern = binding.pattern

            if let pattern = pattern.as(IdentifierPatternSyntax.self) {
                return [pattern.identifier.text]
            } else if let pattern = pattern.as(TuplePatternSyntax.self) {
                return pattern.elements.compactMap {
                    let token = $0.pattern.children(viewMode: .sourceAccurate).mapFirst { $0.as(TokenSyntax.self) }
                    return token?.text
                }
            } else {
                return []
            }
        }

        let items = bindings.flatMap {
            let initializerItems = $0.initializer?.children(viewMode: .sourceAccurate).compactMap { parse(node: $0, collector) } ?? []
            let accessorItems = $0.accessorBlock?.children(viewMode: .sourceAccurate).compactMap { parse(node: $0, collector) } ?? []
            return initializerItems + accessorItems
        }

        return Variable(names: names, items: items)
    }

    private func parse(identifier: TokenSyntax) -> Item {
        // Strip backquotes so that '`class`' becomes just 'class'.
        let name = identifier.text.replacingOccurrences(of: "`", with: "")
        return Identifier(name: name)
    }

    private func parse(functionDecl syntax: FunctionDeclSyntax, _ collector: Collector<some Any>?) -> Item? {
        build(function: syntax.signature,
              attributes: syntax.attributes,
              genericParams: syntax.genericParameterClause,
              body: syntax.body,
              named: syntax.name.text,
              position: syntax.name.positionAfterSkippingLeadingTrivia,
              collector)
    }

    private func parse(initializerDecl syntax: InitializerDeclSyntax, _ collector: Collector<some Any>?) -> Item? {
        build(function: syntax.signature,
              attributes: syntax.attributes,
              genericParams: syntax.genericParameterClause,
              body: syntax.body,
              named: "init",
              position: syntax.initKeyword.positionAfterSkippingLeadingTrivia,
              collector)
    }

    // swiftlint:disable:next function_parameter_count
    private func build(
        function syntax: SyntaxProtocol,
        attributes: AttributeListSyntax?,
        genericParams: GenericParameterClauseSyntax?,
        body: CodeBlockSyntax?,
        named name: String,
        position: AbsolutePosition,
        _ collector: Collector<some Any>?
    ) -> Function? {
        if body == nil, !parseProtocols {
            // Function has no body, must be a protocol declaration.
            return nil
        }

        // Swift supports nested functions, so it's possible this function captures a param from an outer function.
        let params = parse(children: syntax.children(viewMode: .sourceAccurate), collecting: Parameter.self)
        let items = parse(node: body, collector)?.items ?? []
        let fullName = buildFullName(for: name, with: params)
        let genericParamNames = genericParams?.parameters.map(\.name.text) ?? []
        let attributeNames = attributes?.children(viewMode: .sourceAccurate).compactMap { AttributeSyntax($0)?.attributeName.trimmedDescription } ?? []

        let function = Function(
            name: name,
            fullName: fullName,
            location: sourceLocation(of: position),
            items: items,
            parameters: params,
            genericParameters: genericParamNames,
            attributes: attributeNames
        )

        params.forEach { $0.function = function }
        return function
    }

    private func buildFullName(for function: String, with params: [Parameter]) -> String {
        let strParams = params.map {
            [$0.firstName, $0.secondName].compactMap { $0 }.joined(separator: " ")
        }.joined(separator: ":")
        return "\(function)(\(strParams):)"
    }

    private func sourceLocation(of position: AbsolutePosition) -> Location {
        let location = locationConverter.location(for: position)
        return Location(file: file,
                        line: location.line,
                        column: location.column)
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

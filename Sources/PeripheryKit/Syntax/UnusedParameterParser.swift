import Foundation
import SystemPackage
import SwiftSyntax
#if canImport(SwiftSyntaxParser)
import SwiftSyntaxParser
#endif

protocol Item: AnyObject {
    var items: [Item] { get }
}

final class Function: Item, Hashable {
    static func == (lhs: Function, rhs: Function) -> Bool {
        lhs.location == rhs.location
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(location)
    }

    let name: String
    let fullName: String
    let location: SourceLocation
    let items: [Item]
    let parameters: [Parameter]
    let genericParameters: [String]
    let attributes: [String]

    init(
        name: String,
        fullName: String,
        location: SourceLocation,
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

final class Parameter: Item, Hashable {
    static func == (lhs: Parameter, rhs: Parameter) -> Bool {
        return lhs.location == rhs.location
    }

    func hash(into hasher: inout Hasher) {
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
        let usr = "\(functionName)-\(name)-\(location)"
        let decl = Declaration(kind: .varParameter, usrs: [usr], location: location)
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
        let syntax = try SyntaxParser.parse(file.path.url)
        let locationConverter = SourceLocationConverter(file: file.path.string, tree: syntax)
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
        return parse(node: syntax, collecting: Function.self)
    }

    // MARK: - Private

    private func parse<T: Item>(node: SyntaxProtocol, collecting: T.Type) -> [T] {
        return parse(children: node.children(viewMode: .sourceAccurate), collecting: collecting)
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
            parsed = parse(identifier: node.identifier)
        } else if let node = node.as(FunctionParameterSyntax.self) {
            parsed = parse(functionParameter: node)
        } else if let node = node.as(FunctionDeclSyntax.self) {
            parsed = parse(functionDecl: node, collector)
        } else if let node = node.as(InitializerDeclSyntax.self) {
            parsed = parse(initializerDecl: node, collector)
        } else if let optBindingCondition = node.as(OptionalBindingConditionSyntax.self) {
            if optBindingCondition.initializer == nil,
               let pattern = optBindingCondition.pattern.as(IdentifierPatternSyntax.self),
               let parentStmt = optBindingCondition.parent?.parent?.parent,
               (parentStmt.is(IfStmtSyntax.self) || parentStmt.is(GuardStmtSyntax.self)) {
                // Handle `let x {}` syntax.
                parsed = parse(identifier: pattern.identifier)
            } else {
                parsed = parse(childrenFrom: node, collector)
            }
        } else {
            parsed = parse(childrenFrom: node, collector)
        }

        if let collector = collector, let parsed = parsed {
            collector.add(parsed)
        }

        return parsed
    }

    private func parse<T>(childrenFrom node: Syntax, _ collector: Collector<T>?) -> Item? {
        let items = node.children(viewMode: .sourceAccurate).compactMap { parse(node: $0, collector) }
        if items.count > 0 {
            return GenericItem(node: node, items: items)
        }
        return nil
    }

    private func parse(functionParameter syntax: FunctionParameterSyntax) -> Item {
        var metatype: String?

        if let optionalType = syntax.type?.as(OptionalTypeSyntax.self) {
            if let metatypeSyntax = optionalType.children(viewMode: .sourceAccurate).mapFirst({ $0.as(MetatypeTypeSyntax.self) }) {
                metatype = metatypeSyntax.description
            } else if let memberType = optionalType.children(viewMode: .sourceAccurate).mapFirst({ $0.as(MemberTypeIdentifierSyntax.self) }) {
                metatype = parseMetatype(from: memberType)
            }
        } else if let optionalType = syntax.type?.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            if let metatypeSyntax = optionalType.children(viewMode: .sourceAccurate).mapFirst({ $0.as(MetatypeTypeSyntax.self) }) {
                metatype = metatypeSyntax.description
            } else if let memberType = optionalType.children(viewMode: .sourceAccurate).mapFirst({ $0.as(MemberTypeIdentifierSyntax.self) }) {
                metatype = parseMetatype(from: memberType)
            }
        } else if let metatypeSyntax = syntax.type?.as(MetatypeTypeSyntax.self) {
            metatype = metatypeSyntax.description
        } else if let memberType = syntax.type?.as(MemberTypeIdentifierSyntax.self) {
            metatype = parseMetatype(from: memberType)
        }

        let positionSyntax: SyntaxProtocol = (syntax.secondName ?? syntax.firstName) ?? syntax
        let location = sourceLocation(of: positionSyntax.positionAfterSkippingLeadingTrivia)

        return Parameter(firstName: syntax.firstName?.text,
                         secondName: syntax.secondName?.text,
                         metatype: metatype,
                         location: location)
    }

    private func parseMetatype(from syntax: MemberTypeIdentifierSyntax) -> String? {
        // Workaround change in latest SwiftSyntax where T.Type and T.Protocol are no longer a MetatypeTypeSyntax.
        let memberName = syntax.name.text
        if memberName == "Type" || memberName == "Protocol" {
            return syntax.description
        }

        return nil
    }

    private func parse<T>(closureExpr syntax: ClosureExprSyntax, _ collector: Collector<T>?) -> Closure? {
        let signature = syntax.children(viewMode: .sourceAccurate).mapFirst { $0.as(ClosureSignatureSyntax.self) }
        let rawParams = signature?.input?.children(viewMode: .sourceAccurate).compactMap { $0.as(ClosureParamSyntax.self) }
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
                    let token = $0.pattern.children(viewMode: .sourceAccurate).mapFirst { $0.as(TokenSyntax.self) }
                    return token?.text
                }
            } else {
                return []
            }
        }

        let items = bindings.flatMap {
            return $0.initializer?.children(viewMode: .sourceAccurate).compactMap { parse(node: $0, collector) } ?? []
        }

        return Variable(names: names, items: items)
    }

    private func parse(identifier: TokenSyntax) -> Item {
        // Strip backquotes so that '`class`' becomes just 'class'.
        let name = identifier.text.replacingOccurrences(of: "`", with: "")
        return Identifier(name: name)
    }

    private func parse<T>(functionDecl syntax: FunctionDeclSyntax, _ collector: Collector<T>?) -> Item? {
        return build(function: syntax.signature,
                     attributes: syntax.attributes,
                     genericParams: syntax.genericParameterClause,
                     body: syntax.body,
                     named: syntax.identifier.text,
                     position: syntax.identifier.positionAfterSkippingLeadingTrivia,
                     collector)
    }

    private func parse<T>(initializerDecl syntax: InitializerDeclSyntax, _ collector: Collector<T>?) -> Item? {
        return build(function: syntax.signature,
                     attributes: syntax.attributes,
                     genericParams: syntax.genericParameterClause,
                     body: syntax.body,
                     named: "init",
                     position: syntax.initKeyword.positionAfterSkippingLeadingTrivia,
                     collector)
    }

    private func build<T>(
        function syntax: SyntaxProtocol,
        attributes: AttributeListSyntax?,
        genericParams: GenericParameterClauseSyntax?,
        body: CodeBlockSyntax?,
        named name: String,
        position: AbsolutePosition,
        _ collector: Collector<T>?
    ) -> Function? {
        if body == nil && !parseProtocols {
            // Function has no body, must be a protocol declaration.
            return nil
        }

        // Swift supports nested functions, so it's possible this function captures a param from an outer function.
        let params = parse(children: syntax.children(viewMode: .sourceAccurate), collecting: Parameter.self)
        let items = parse(node: body, collector)?.items ?? []
        let fullName = buildFullName(for: name, with: params)
        let genericParamNames = genericParams?.genericParameterList.compactMap { $0.name.text } ?? []
        let attributeNames = attributes?.children(viewMode: .sourceAccurate).compactMap { AttributeSyntax($0)?.attributeName.text } ?? []

        let function = Function(
            name: name,
            fullName: fullName,
            location: sourceLocation(of: position),
            items: items,
            parameters: params,
            genericParameters: genericParamNames,
            attributes: attributeNames)

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
        return SourceLocation(file: file,
                              line: Int64(location.line ?? 0),
                              column: Int64(location.column ?? 0))
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

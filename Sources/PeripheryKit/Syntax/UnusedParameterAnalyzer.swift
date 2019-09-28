import Foundation
import PathKit

final class UnusedParameterAnalyzer {
    private enum UsageType {
        case used
        case unused
        case shadowed
    }

    func analyze(file: Path, parseProtocols: Bool) throws -> Set<Parameter> {
        let parser = UnusedParamParser(file: file, parseProtocols: parseProtocols)
        let functions = try parser.parse()
        return Set(functions.flatMap { analyze(function: $0) })
    }

    func analyze(file: Path, json: String, parseProtocols: Bool) throws -> Set<Parameter> {
        let parser = UnusedParamParser(file: file, parseProtocols: parseProtocols)
        let functions = try parser.parse(syntaxTreeJson: json)
        return Set(functions.flatMap { analyze(function: $0) })
    }

    func analyze(function: Function) -> Set<Parameter> {
        return Set(unusedParams(in: function))
    }

    // MARK: - Private

    private func unusedParams(in function: Function) -> [Parameter] {
        return function.parameters.filter { !isParam($0, usedIn: function) }
    }

    private func isParam(_ param: Parameter, usedIn function: Function) -> Bool {
        if param.name == "_" {
            // Params named '_' are explicitly not intended for use, ignore them.
            return true
        }

        if isParam(param, usedForSpecializationIn: function) {
            return true
        }

        if isFunctionFatalErrorOnly(function) {
            return true
        }

        return isParam(param, usedIn: function.items)
    }

    private func isFunctionFatalErrorOnly(_ function: Function) -> Bool {
        guard let codeBlockList = function.items.first as? GenericItem,
            codeBlockList.kind == "CodeBlockItemListSyntax",
            codeBlockList.items.count == 1,
            let funcCallExpr = codeBlockList.items.first as? GenericItem,
            funcCallExpr.kind == "FunctionCallExprSyntax",
            let identifier = funcCallExpr.items.first as? Identifier
            else { return false }

        return identifier.name == "fatalError"
    }

    private func isParam(_ param: Parameter, usedIn items: [Item]) -> Bool {
        for item in items {
            switch usage(of: param, in: item) {
            case .used:
                return true
            case .shadowed:
                return false
            case .unused:
                break
            }
        }

        return false
    }

    private func isParam(_ param: Parameter, usedIn item: Item) -> Bool {
        switch usage(of: param, in: item) {
        case .used:
            return true
        case .shadowed, .unused:
            return false
        }
    }

    private func usage(of param: Parameter, in item: Item) -> UsageType {
        switch item {
        case let item as Variable:
            // First check if the param is used in the assignment expression.
            if isParam(param, usedIn: item.items) {
                return .used
            }

            // Next check if the variable shadows the param.
            if item.names.contains(param.name) {
                return .shadowed
            }

            return .unused
        case let item as Closure:
            if item.params.contains(param.name) {
                return .shadowed
            }

            if isParam(param, usedIn: item.items) {
                return .used
            }
        case let item as Identifier:
            return item.name == param.name ? .used : .unused
        case let item as GenericItem where item.kind == "FunctionCallArgumentListSyntax":
            for item in item.items {
                if isParam(param, usedIn: item) {
                    return .used
                }
            }

            return .unused
        default:
            if isParam(param, usedIn: item.items) {
                return .used
            }
        }

        return .unused
    }

    private func isParam(_ param: Parameter, usedForSpecializationIn function: Function) -> Bool {
        guard let metatype = param.metatype else { return false }

        let parts = metatype.split(separator: ".").map { String($0) }

        guard let genericParam = parts.first,
            let member = parts.last,
            member == "Type" else { return false }

        return function.genericParameters.contains(genericParam)
    }
}

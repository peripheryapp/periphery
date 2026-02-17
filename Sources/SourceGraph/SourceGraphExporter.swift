// periphery:ignore:all

import Foundation

public enum JSON {
    case object([String:JSON])
    case array([JSON])
    case string(String)
    case bool(Bool)
    case null
}

extension JSON: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .object(let dictionary):
            try container.encode(dictionary)
        case .array(let array):
            try container.encode(array)
        case .string(let string):
            try container.encode(string)
        case .bool(let bool):
            try container.encode(bool)
        case .null:
            try container.encodeNil()
        }
    }
}

public final class SourceGraphExporter {
    private let graph: SourceGraph

    public required init(graph: SourceGraph) {
        self.graph = graph
    }

    public func describeGraph() -> JSON {
        var dictionary = [String:JSON]()
        dictionary["rootDeclarations"] = describe(graph.rootDeclarations.sorted())
        dictionary["rootReferences"] = describe(graph.rootReferences.sorted())
        return .object(dictionary)
    }

    // MARK: - Private

    private func describe(_ declarations: any Sequence<Declaration>) -> JSON {
        .array(declarations.map(describe))
    }

    private func describe(_ references: any Sequence<Reference>) -> JSON {
        .array(references.map(describe))
    }

    private func describe(_ declaration: Declaration)  -> JSON {
        var dictionary = [String:JSON]()
        dictionary["$isa"] = .string("declaration")

        dictionary["location"] = describe(declaration.location)
        dictionary["attributes"] = describe(declaration.attributes)
        dictionary["modifiers"] = describe(declaration.modifiers)
        dictionary["accessibility"] = describe(declaration.accessibility.value)
        dictionary["kind"] = describe(declaration.kind)
        dictionary["name"] = describe(declaration.name)
        dictionary["usrs"] = describe(declaration.usrs)
        dictionary["unusedParameters"] = describe(declaration.unusedParameters)
        dictionary["declarations"] = describe(declaration.declarations)
        dictionary["references"] = describe(declaration.references)
        dictionary["declaredType"] = describe(declaration.declaredType)
        dictionary["displayName"] = describe(declaration.kind.displayName)

        if let parent = declaration.parent {
            dictionary["parent"] = .array(parent.usrs.map({.string($0)}))
        }
        dictionary["immediateInheritedTypeReferences"] = describe(declaration.immediateInheritedTypeReferences)
        dictionary["isImplicit"] = describe(declaration.isImplicit)
        dictionary["isObjcAccessible"] = describe(declaration.isObjcAccessible)

        dictionary["related"] = describe(declaration.related)
        dictionary["references"] = describe(declaration.references)
        dictionary["declarations"] = describe(declaration.declarations)
        return .object(dictionary)
    }

    private func describe(_ reference: Reference) -> JSON {
        return describe(reference.usr)
    }

    // MARK: - Extra

    private func describe(_ value: Location) -> JSON {
        return .string(value.file.path.string)
    }

    private func describe(_ value: Declaration.Kind) -> JSON {
        .string(value.rawValue)
    }

    private func describe(_ value: Reference.Role) -> JSON {
        .string(value.rawValue)
    }

    private func describe(_ value: String?) -> JSON {
        if let value {
            return .string(value)
        } else {
            return .null
        }
    }

    private func describe(_ value: Set<String>) -> JSON {
        return .array(value.sorted().map(describe))
    }

    private func describe<T: RawRepresentable>(_ value: T) -> JSON where T.RawValue == String {
        describe(value.rawValue)
    }

    private func describe(_ value: Bool) -> JSON {
        return .bool(value)
    }
}

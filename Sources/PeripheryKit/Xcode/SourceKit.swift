import Foundation
import SourceKittenFramework
import PathKit

final class SourceKit {
    enum Key: String {
        case entities = "key.entities"
        case kind = "key.kind"
        case usr = "key.usr"
        case line = "key.line"
        case column = "key.column"
        case isDynamic = "key.is_dynamic"
        case name = "key.name"
        case receiverUsr = "key.receiver_usr"
        case related = "key.related"
        case attributes = "key.attributes"
        case attribute = "key.attribute"
        case substructure = "key.substructure"
        case accessibility = "key.accessibility"
    }

    @available(*, deprecated, message: "Indexing with SoruceKit is deprecated. Please use IndexStore versioin instead")
    static func make(buildPlan: BuildPlan, target: Target) throws -> Self {
        let arguments = try buildPlan.arguments(for: target)
        return self.init(arguments: arguments)
    }

    static func make() -> Self {
        return self.init(arguments: [])
    }

    private let arguments: [String]

    required init(arguments: [String]) {
        self.arguments = arguments
    }

    func editorOpen(_ file: SourceFile) throws -> [String: Any] {
        let response: [String: Any]

        do {
            // FIXME: Cache response
            response = try Request.editorOpen(file: File(path: file.path.string)!).send()
        } catch {
            throw PeripheryKitError.sourceKitRequestFailed(type: "index", file: file.path.string, error: error)
        }

        return response
    }

    @available(*, deprecated, message: "Indexing with SoruceKit is deprecated. Please use IndexStore versioin instead")
    func requestIndex(_ file: SourceFile) throws -> [String: Any] {
        let response: [String: Any]

        do {
            response = try Request.index(file: file.path.string, arguments: arguments).send()
        } catch {
            throw PeripheryKitError.sourceKitRequestFailed(type: "index", file: file.path.string, error: error)
        }

        return response
    }

    func editorOpenSyntaxTree(_ file: SourceFile) throws -> [String: Any] {
        let request: SourceKitObject = [
            "key.request": UID("source.request.editor.open"),
            "key.name": NSUUID().uuidString,
            "key.sourcefile": file.path.string,
            "key.enablesyntaxmap": 0,
            "key.enablesubstructure": 0,
            "key.enablesyntaxtree": 1,
            "key.syntactic_only": 1,
            "key.syntaxtreetransfermode": UID("source.syntaxtree.transfer.full"),
            "key.syntax_tree_serialization_format":
                UID("source.syntaxtree.serialization.format.json")
        ]
        let response: [String: Any]

        do {
            response = try Request.customRequest(request: request).send()
        } catch {
            throw PeripheryKitError.sourceKitRequestFailed(type: "editorOpenSyntaxTree", file: file.path.string, error: error)
        }

        return response
    }

    func editorOpenSubstructure(_ file: SourceFile) throws -> [String: Any] {
        let request: SourceKitObject = [
            "key.request": UID("source.request.editor.open"),
            "key.name": NSUUID().uuidString,
            "key.sourcefile": file.path.string,
            "key.enablesyntaxmap": 0,
            "key.enablesubstructure": 1,
            "key.enablesyntaxtree": 0,
        ]
        let response: [String: Any]

        do {
            response = try Request.customRequest(request: request).send()
        } catch {
            throw PeripheryKitError.sourceKitRequestFailed(type: "editorOpenSubstructure", file: file.path.string, error: error)
        }

        return response
    }

    func cursorInfo(file: SourceFile, offset: Int64) throws -> [String: Any] {
        let request: SourceKitObject = [
            "key.request": UID("source.request.cursorinfo"),
            "key.name": NSUUID().uuidString,
            "key.sourcefile": file.path.string,
            "key.offset": offset,
            "key.compilerargs": arguments
        ]
        let response: [String: Any]

        do {
            response = try Request.customRequest(request: request).send()
        } catch {
            throw PeripheryKitError.sourceKitRequestFailed(type: "cursorInfo", file: file.path.string, error: error)
        }

        return response
    }
}

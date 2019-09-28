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
        case serializedSyntaxTree = "key.serialized_syntax_tree"
    }

    static func make(buildPlan: BuildPlan, target: Target) throws -> Self {
        let arguments = try buildPlan.arguments(for: target)
        return self.init(arguments: arguments)
    }

    private let arguments: [String]

    required init(arguments: [String]) {
        self.arguments = arguments
    }

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

    func syntaxTree(file: Path) throws -> [String: Any] {
        let response: [String: Any]

        do {
            let skFile = SourceKittenFramework.File(pathDeferringReading: file.string)
            response = try Request.syntaxTree(file: skFile, byteTree: false).send()
        } catch {
            throw PeripheryKitError.sourceKitRequestFailed(type: "syntaxTree", file: file.string, error: error)
        }

        return response
    }
}

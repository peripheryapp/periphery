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
        case isImplicit = "key.is_implicit"
        case name = "key.name"
        case receiverUsr = "key.receiver_usr"
        case related = "key.related"
        case attributes = "key.attributes"
        case attribute = "key.attribute"
        case substructure = "key.substructure"
        case accessibility = "key.accessibility"
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
}

import Foundation

let simpleType: String = ""
var optionalType: String?
let memberType: Swift.String = ""
let tupleType: (String, Int) = ("", 0)
let dictionaryType: [String: Int] = [:]
let arrayType: [String] = []
func functionSimpleReturnType() -> String { "" }
func functionClosureReturnType() -> (Int) -> String {
    let closure: (Int) -> String = { String($0) }
    return closure
}
func functionArgumentType(a: String, b: Int) {}
func genericFunction<T: StringProtocol & AnyObject>(_ t: T.Type) where T: RawRepresentable {}
@available(macOS 10.15.0, *)
func functionSomeType() -> some StringProtocol { "" }

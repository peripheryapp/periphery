import Foundation
import PathKit

var ProjectRootPath: Path {
    let file = #file
    return Path(file) + "../../.."
}

var PeripheryProjectPath: Path {
    return ProjectRootPath + "Periphery.xcodeproj"
}

import XCTest
// Pollyfill for XCTUnwrap because it's not available on SwiftPM yet.
struct XCTUnwrapError: Swift.Error {}
func XCTUnwrap<T>(_ expression: @autoclosure () throws -> T?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) throws -> T {
    guard let value = try expression() else {
        XCTFail("expected non-nil value of type \(T.self): " + message(), file: file, line: line)
        throw XCTUnwrapError()
    }
    return value
}

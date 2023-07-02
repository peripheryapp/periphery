//
//  File.swift
//  
//
//  Created by Ian Leitch on 02.07.23.
//

import Foundation
import XCTest
@testable import XcodeSupport
@testable import PeripheryKit

final class XcodeBuildActionTests: XCTestCase {
    func testTargetTriples() throws {
        let action = XcodeBuildAction(target: "Test", buildSettings: [
            "CURRENT_ARCH": "arm64",
            "LLVM_TARGET_TRIPLE_VENDOR": "apple",
            "LLVM_TARGET_TRIPLE_OS_VERSION": "ios16"
        ])
        let triple = try action.makeTargetTriple()
        XCTAssertEqual(triple, "arm64-apple-ios16")
    }
}

//
//  RedundantInternalClassComponents.swift
//  
//
//  Created by Dan Wood on 4/18/23.
//

import Foundation

public class RedundantInternalClassComponents {

	public init() {
		let _ = RedundantInternalSubclass()
		let _ = RedundantInternalStruct()
		let _ = RedundantInternalEnum.a
		Self.aRedundantInternalFunc()
		let _ = Self.aRedundantInternalVar

		let _ = ClassThatCanBePrivate()
	}

	// Used only in this file, so they should be private.

	class RedundantInternalSubclass {}
	struct RedundantInternalStruct {}
	enum RedundantInternalEnum {
		case a
	}
	static func aRedundantInternalFunc() {}
	static var aRedundantInternalVar: Int = 0
}

extension RedundantInternalClassComponents {

	// Also should be private
	
	class ExtensionRedundantInternalSubclass {}
	struct ExtensionRedundantInternalStruct {}
	enum ExtensionRedundantInternalEnum {
		case a
	}
	static func aExtensionRedundantInternalFunc() {}
	static var aExtensionRedundantInternalVar: Int = 0

}

class ClassThatCanBePrivate {

	static func FunctionThatShouldBePrivateInPrivateClass() {}
}

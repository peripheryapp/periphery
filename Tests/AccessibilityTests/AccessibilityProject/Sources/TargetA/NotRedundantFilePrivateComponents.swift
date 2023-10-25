//
//  NotRedundantFilePrivateComponents.swift
//  
//
//  Created by Dan Wood on 4/18/23.
//

import Foundation

public class NotRedundantFilePrivateComponents {

	public init() {
		let _ = SubclassCorrectlyFilePrivate()
		let _ = StructCorrectlyFilePrivate()
		let _ = EnumCorrectlyFilePrivate.a
		Self.aFuncCorrectlyFilePrivate()
		let _ = Self.aVarCorrectlyFilePrivate
	}

	// fileprivate is correct here since they are used in the other class below.
	fileprivate class SubclassCorrectlyFilePrivate {}
	fileprivate struct StructCorrectlyFilePrivate {}
	fileprivate enum EnumCorrectlyFilePrivate {
		case a
	}
	fileprivate static func aFuncCorrectlyFilePrivate() {}
	fileprivate static var aVarCorrectlyFilePrivate: Int = 0
}

private class AnotherClassUsingTheseComponents {

	public init() {
		let _ = NotRedundantFilePrivateComponents.SubclassCorrectlyFilePrivate()
		let _ = NotRedundantFilePrivateComponents.StructCorrectlyFilePrivate()
		let _ = NotRedundantFilePrivateComponents.EnumCorrectlyFilePrivate.a
		NotRedundantFilePrivateComponents.aFuncCorrectlyFilePrivate()
		let _ = NotRedundantFilePrivateComponents.aVarCorrectlyFilePrivate
	}

}


extension NotRedundantFilePrivateComponents {

	// fileprivate is correct here since they are used in the other class below.
	fileprivate class ExtensionSubclassCorrectlyFilePrivate {}
	fileprivate struct ExtensionStructCorrectlyFilePrivate {}
	fileprivate enum ExtensionEnumCorrectlyFilePrivate {
		case a
	}
	fileprivate static func aExtensionFuncCorrectlyFilePrivate() {}
	fileprivate static var aExtensionVarCorrectlyFilePrivate: Int = 0
}

extension AnotherClassUsingTheseComponents {

	private func something() {
		let _ = NotRedundantFilePrivateComponents.ExtensionSubclassCorrectlyFilePrivate()
		let _ = NotRedundantFilePrivateComponents.ExtensionStructCorrectlyFilePrivate()
		let _ = NotRedundantFilePrivateComponents.ExtensionEnumCorrectlyFilePrivate.a
		NotRedundantFilePrivateComponents.aExtensionFuncCorrectlyFilePrivate()
		let _ = NotRedundantFilePrivateComponents.aExtensionVarCorrectlyFilePrivate
	}

}

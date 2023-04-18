//
//  RedundantFilePrivateComponents.swift
//  
//
//  Created by Dan Wood on 4/18/23.
//

import Foundation

public class RedundantFilePrivateComponents {

	public init() {
		let _ = SubclassThatShouldNotBeFilePrivate()
		let _ = StructThatShouldNotBeFilePrivate()
		let _ = EnumThatShouldNotBeFilePrivate.a
		Self.aFuncThatShouldNotBeFilePrivate()
		let _ = Self.aVarThatShouldNotBeFilePrivate
		let _ = ClassThatShouldNotBeFilePrivate()
	}

	// fileprivate is not ideal here; these could be private since they are not used outside of this class scope

	fileprivate class SubclassThatShouldNotBeFilePrivate {}
	fileprivate struct StructThatShouldNotBeFilePrivate {}
	fileprivate enum EnumThatShouldNotBeFilePrivate {
		case a
	}
	fileprivate static func aFuncThatShouldNotBeFilePrivate() {}
	fileprivate static var aVarThatShouldNotBeFilePrivate: Int = 0
}

// This can just be private
fileprivate class ClassThatShouldNotBeFilePrivate {}

extension RedundantFilePrivateComponents {

	// These could also be private

	fileprivate class ExtensionSubclassThatShouldNotBeFilePrivate {}
	fileprivate struct ExtensionStructThatShouldNotBeFilePrivate {}
	fileprivate enum ExtensionEnumThatShouldNotBeFilePrivate {
		case a
	}
	fileprivate static func aExtensionFuncThatShouldNotBeFilePrivate() {}
	fileprivate static var aExtensionVarThatShouldNotBeFilePrivate: Int = 0

}

//
//  NotRedundantInternalClassComponents.swift
//  
//
//  Created by Dan Wood on 4/18/23.
//

import Cocoa

public class NotRedundantInternalClassComponents {

	public init() {
		let _ = NotRedundantInternalSubclass()
		let _ = NotRedundantInternalStruct()
		let _ = NotRedundantInternalEnum.a
		Self.aNotRedundantInternalFunc()
		let _ = Self.aNotRedundantInternalVar
	}

	// Declared here, but also used in NotRedundantInternalClassComponents_Support so they shouldn't be private
	class NotRedundantInternalSubclass {}
	struct NotRedundantInternalStruct {}
	enum NotRedundantInternalEnum {
		case a
	}
	static func aNotRedundantInternalFunc() {}
	static var aNotRedundantInternalVar: Int = 0

}

extension NotRedundantInternalClassComponents {

	class ExtensionNotRedundantInternalSubclass {}
	struct ExtensionNotRedundantInternalStruct {}
	enum ExtensionNotRedundantInternalEnum {
		case a
	}
	static func aExtensionNotRedundantInternalFunc() {}
	static var aExtensionNotRedundantInternalVar: Int = 0


}


public protocol MyProtocol {

	@available(iOS 2.0, *)
	static func protocolMethod()
}


private class NotRedundantInternalClassCompontentsConformingToProtocol: MyProtocol {

	static func protocolMethod() { }
}

private class NotRedundantInternalClassCompontentsConformingToAppKitProtocol: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ notification: Notification) {}

}

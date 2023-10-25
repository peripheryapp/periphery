//
//  NotRedundantInternalClassComponents_Support.swift
//  
//
//  Created by Dan Wood on 4/18/23.
//

import Foundation

// A different file using the components of NotRedundantInternalClassComponents that shouldn't be private
public class NotRedundantInternalClassComponents_Support {

	public init() {
		let _ = NotRedundantInternalClassComponents.NotRedundantInternalSubclass()
		let _ = NotRedundantInternalClassComponents.NotRedundantInternalStruct()
		let _ = NotRedundantInternalClassComponents.NotRedundantInternalEnum.a
		NotRedundantInternalClassComponents.aNotRedundantInternalFunc()
		let _ = NotRedundantInternalClassComponents.aNotRedundantInternalVar

		let _ = NotRedundantInternalClassComponents.ExtensionNotRedundantInternalSubclass()
		let _ = NotRedundantInternalClassComponents.ExtensionNotRedundantInternalStruct()
		let _ = NotRedundantInternalClassComponents.ExtensionNotRedundantInternalEnum.a
		NotRedundantInternalClassComponents.aExtensionNotRedundantInternalFunc()
		let _ = NotRedundantInternalClassComponents.aExtensionNotRedundantInternalVar
	}

}

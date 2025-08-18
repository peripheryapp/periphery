@attached(peer, names: suffixed(Mock))
public macro Mock() = #externalMacro(module: "SPMProjectMacros", type: "MockMacro")

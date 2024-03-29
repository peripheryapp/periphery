func functionWithSimpleReturnType() -> Bool {
    return true
}

func functionWithTupleReturnType() -> (String, Int) {
    return ("", 1)
}

func functionWithPrefixedReturnType() -> Swift.String {
    return ""
}

func functionWithClosureReturnType() -> (Int) -> String {
    let closure: (Int) -> String = { String($0) }
    return closure
}

func functionWithArguments(a: String, b: Int) {}

func functionWithGenericArgument<T: StringProtocol & AnyObject>(_ t: T.Type) where T: RawRepresentable {}

@available(macOS 10.15.0, *)
func functionWithSomeReturnType() -> some StringProtocol { "" }

class FixtureClass1 {
    init(a: String, b: Int) {}
}

class FixtureClass2 {
    init<T: StringProtocol & AnyObject>(_ t: T.Type) where T: RawRepresentable {}
}

class FixtureClass3 {
    subscript(a: Int, b: String) -> Int { 0 }
    subscript<T: StringProtocol & AnyObject>(_ t: T.Type) -> Int where T: RawRepresentable { 0 }
}

import Foundation

struct CaptureListFixtureState {
    var someProperty: String
}

class CaptureListFixture {
    // Parameter used in capture list should be considered used
    func functionWithCaptureList(_ state: CaptureListFixtureState) -> () -> String {
        return { [someProperty = state.someProperty] in
            return someProperty
        }
    }

    // Multiple parameters used in capture list
    func multipleParamsInCaptureList(param1: String, param2: Int, unusedParam: Bool) -> () -> String {
        return { [captured1 = param1, captured2 = param2] in
            return "\(captured1) \(captured2)"
        }
    }

    // Parameter used both in capture list and directly - should be used
    func paramUsedInCaptureListAndDirectly(param: String) -> () -> String {
        print(param)
        return { [captured = param] in
            return captured
        }
    }

    // Weak capture (common pattern for avoiding retain cycles)
    func weakCapture(object: AnyObject) -> () -> Void {
        return { [weak object] in
            _ = object
        }
    }

    // Nested closure with capture list
    func nestedClosureWithCaptureList(outerParam: String) -> () -> () -> String {
        return {
            return { [captured = outerParam] in
                return captured
            }
        }
    }

    // Shorthand capture (just [param] without assignment)
    func shorthandCapture(param: String) -> () -> String {
        return { [param] in
            return param
        }
    }

    // Capture list only - parameter not used in body, only in capture
    func captureListOnly(param: String) -> () -> String {
        return { [captured = param] in
            return "constant"
        }
    }
}


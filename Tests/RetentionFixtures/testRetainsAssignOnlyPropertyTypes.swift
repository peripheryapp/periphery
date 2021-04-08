public class FixtureClass123 {
    struct CustomType {}

    var retainedAssignOnlyProperty: CustomType?
    var notRetainedAssignOnlyProperty: String?

    public func someFunc() {
        retainedAssignOnlyProperty = CustomType()
        notRetainedAssignOnlyProperty = ""
    }
}

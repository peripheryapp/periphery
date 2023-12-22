public class PublicEnumCaseWithParameter_ParameterType {}
public class PublicEnumCaseWithParameter_ParameterType_Outer {
    public class Inner {}
}
public enum PublicEnumCaseWithParameter {
    case someCase(
        param1: PublicEnumCaseWithParameter_ParameterType?,
        param2: PublicEnumCaseWithParameter_ParameterType_Outer.Inner?
    )
}

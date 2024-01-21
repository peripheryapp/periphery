enum EnumCaseRemoval {
    case used
    case unused
}

public class EnumCaseRemovalRetainer {
    public func retain() {
        _ = EnumCaseRemoval.used
    }
}

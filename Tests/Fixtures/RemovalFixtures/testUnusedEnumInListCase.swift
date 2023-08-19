enum EnumInListCaseRemoval {
    case used1, unused1, used2, unused2
}

public class EnumInListCaseRemovalRetainer {
    public func retain() {
        _ = EnumInListCaseRemoval.used1
        _ = EnumInListCaseRemoval.used2
    }
}

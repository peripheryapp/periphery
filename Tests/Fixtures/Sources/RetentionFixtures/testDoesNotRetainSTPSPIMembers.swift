import Foundation

// Test that @_spi(STP) public members are NOT retained by retain_public
public class FixtureClass220 {
    // Regular public should be retained
    public func publicFunc() {}

    // @_spi(STP) public should NOT be retained (treated as internal)
    @_spi(STP) public func stpSpiFunc() {}

    // @_spi(OtherSPI) public should still be retained (only STP is special)
    @_spi(OtherSPI) public func otherSpiFunc() {}

    // Internal should not be retained
    internal func internalFunc() {}

    // Private should not be retained
    private func privateFunc() {}
}

// Test with a struct as well
@_spi(STP) public struct FixtureStruct220 {
    public func someFunc() {}
}

// Test with regular public struct for comparison
public struct FixtureStruct221 {
    public func someFunc() {}
}

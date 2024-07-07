import CrossModuleRetentionSupportFixtures

class FixtureClass129: CrossModuleRetentionSupportFixtures.FixtureClass129 {}

// Explicitly retain CrossModuleRetentionFixtures.FixtureClass129 as we can't use
// --retain-public because it'll also retain CrossModuleRetentionSupportFixtures.FixtureClass129.
// periphery:ignore
class FixtureClass129Retainer {
    func retain() {
        _ = FixtureClass129.self
    }
}

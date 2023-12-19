import Foundation

@propertyWrapper public struct PublicWrapper {
  public var wrappedValue: String

  public init(wrappedValue: String) {
    self.wrappedValue = wrappedValue
  }
}

public struct PublicWrappedProperty {
  @PublicWrapper public var wrappedProperty: String

  public init() {
      wrappedProperty = ""
  }
}

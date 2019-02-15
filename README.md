<h1 align="center">
  <br>
  <img src="assets/logo.png" alt="Periphery" width="180" height="180">
  <br>
  Periphery
  <br>
</h1>

<h4 align="center">Eliminate unused Swift code.</h4>

<p align="center">
  <a href="#installation">Installation</a> •
  <a href="#how-to-use">How To Use</a> •
  <a href="#how-it-works">How It Works</a> •
  <a href="#analysis">Analysis</a>
</p>

<p align="center">
<hr>
Periphery was previously a closed-source product, and is still in the process of transitioning to an open-source environment. For now, documentation can still be found here: https://peripheryapp.com/documentation.
<hr>
</p>

## Installation

### 1. Install the Homebrew package manager

Periphery is distributed via [Homebrew](https://brew.sh/), a package manager popular with many developers using macOS. If you're already a Homebrew user, you can skip this step.

Install Homebrew:

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

### 2. Install Periphery

Now that Homebrew is installed, we need to tell it where to find Periphery releases:

```
brew tap peripheryapp/periphery
```

Next, install Periphery itself:

```
brew cask install periphery
```

## How To Use

### The `scan` Command

The scan command is Periphery's primary function. To begin a guided setup, simply change to your project directory and run:

```
periphery scan
```

After answering a few questions, Periphery will print out the full scan command and execute it.

The guided setup is only intended for introductory purposes, once you are familiar with Periphery you can try some more advanced options, all of which can be seen with `periphery help scan`.

### The `scan-syntax` Command

Whereas the `scan` command performs a full static analysis of your build targets, the `scan-syntax` only perform analysis techniques that use syntax parsing, and is therefore much faster. This currently only includes unused function parameter detection.

Unused function parameter detection when performed by `scan-syntax` is slightly inferior to `scan`, since it cannot use additional information from the compiler to omit redundant results. See [Function Parameters](#function-parameters) for an explanation of the differences.

### Configuration

Once you've settled upon the appropriate options for your project, you may wish to persist them in a YAML configuration file. The simplest way to achieve this is to run Periphery with the `--verbose` option. Near the beginning of the output you will see the `[configuration]` section with your configuration formatted as YAML below. Copy & paste the configuration into `.periphery.yml` in the root of your project folder. You can now simply run `periphery scan` and the YAML configuration will be used.

## How It Works

Periphery first builds all of the schemes provided via the `--schemes` option using `xcodebuild`. It then indexes all files that are members of the targets passed to the `--targets` option, resulting in a graph of declarations and references. Finally, it performs numerous mutations on the graph then analyzes it to identify unused declarations.

For example, if your Xcode workspace consists of a single application and multiple frameworks all defined in separate projects, you'd choose a scheme that builds the application and framework targets. Typically any dependent frameworks would be built implicitly if they're used by the application, so you'd likely only need to specify your application's main scheme.

It's important to specify a complete set of targets for the `--targets` option. For the example above, we'd need to specify the application target, and each framework target. If you did not include your application target, then Periphery would correctly identify that many public interfaces of your frameworks are unused.

The scan options for this example would be as follows:

```
periphery scan --workspace MyApp.xcworkspace --schemes MyApp --targets MyApp,FrameworkA,FrameworkB --format xcode
```

If your project consists of one or more standalone frameworks that do not also contain some kind of application that consume their interfaces, then you'll need to tell Periphery to assume that all public declarations are in fact used by including the `--retain-public` option.

If your project is 100% Swift, then you'll likely want to include the `--no-retain-objc-annotated` option. For projects that are mixed Objective-C/Swift, we highly recommend you [read about the implications](#objective-c) this can have on your results.

## Analysis

The goal of Periphery is to report instances of unused _declarations_. A declaration is a `class`, `struct`, `protocol`, `function`, `property`, `constructor`, `enum`, `typealias` or `associatedtype`. As you'd expect, Periphery is able to identify simple unreferenced declarations, e.g a `class` that is no longer used anywhere in your codebase.

This document aims to explain in detail the more advanced analysis techniques that Periphery employs.

### Function Parameters

Periphery provides two commands for identifying unused function parameters. The `scan-syntax` command is the fastest, yet only analyses functions by parsing syntax. This means some results - while still technically correct - may not be practically useful.

The `scan` command also identifies unused function parameters, but uses the context of your whole application in order to omit results which are not practically useful. The sections below describe the scenarios in which the `scan` command works to provide more useful results.

#### Protocols

An unused parameter of a protocol function will only be reported as unused if the parameter is also unused in all implementations.

```swift
protocol Greeter {
    func greet(name: String)
    func farewell(name: String) // 'name' is unused
}

class InformalGreeter: Greeter {
  func greet(name: String) {
      print("Sup " + name + ".")
  }

  func farewell(name: String) { // 'name' is unused
    print("Cya.")
  }
}
```

> **Tip**
>
> You can ignore all unused parameters from protocols and conforming functions with the `--retain-unused-protocol-func-params` option.

#### Overrides

Similar to protocols, parameters of overridden functions are only reported as unused if they're also unused in the base function and all overriding functions.

```swift
class BaseGreeter {
    func greet(name: String) {
        print("Hello.")
    }

    func farewell(name: String) { // 'name' is unused
        print("Goodbye.")
    }
}

class InformalGreeter: BaseGreeter {
    override func greet(name: String) {
        print("Sup " + name + ".")
    }

    override func farewell(name: String) { // 'name' is unused
      print("Cya.")
    }
}
```

#### Foreign Protocols & Classes

Unused parameters of protocols or classes defined in foreign modules (e.g Foundation) are always ignored, since you do not have access to modify the base function declaration.

#### fatalError Functions

Unused parameters of functions that simply call `fatalError` are also ignored. Such functions are often unimplemented required initializers in subclasses.

```swift
class Base {
    let param: String

    required init(param: String) {
        self.param = param
    }
}

class Subclass: Base {
    init(custom: String) {
        super.init(param: custom)
      }

    required init(param: String) {
        fatalError("init(param:) has not been implemented")
      }
}
```

### Protocols

A protocol which is conformed to by an object is not truly used unless it's also used in a type cast, as a property type, or to specialize a generic method/class, etc. Periphery is able to identify such protocols whether they are conformed to by one, or even multiple objects.

```swift
protocol MyProtocol { // 'MyProtocol' is unused
    func someMethod()
}

class MyClass1: MyProtocol {
    func someMethod() {
        print("Hello from MyClass1!")
  }
}

class MyClass2: MyProtocol {
    func someMethod() {
        print("Hello from MyClass2!")
  }
}

let myClass1 = MyClass1()
myClass1.someMethod()

let myClass2 = MyClass2()
myClass2.someMethod()
```

Here we can see that despite both implementations of `someMethod` are called, at no point does an object take on the type of `MyProtocol`. Therefore the protocol itself is redundant, and there's no benefit from `MyClass1` or `MyClass2` conforming to it. We can remove `MyProtocol` and just keep `someMethod` in each class.

Just like a normal method or property of a object, individual properties and methods declared by your protocol can also be identified as unused.

```swift
protocol MyProtocol {
    var usedProperty: String { get }
    var unusedProperty: String { get } // 'unusedProperty' is unused
}

class MyConformingClass: MyProtocol {
    var usedProperty: String = "used"
    var unusedProperty: String = "unused" // 'unusedProperty' is unused
}

class MyClass {
    let conformingClass: MyProtocol

    init() {
        conformingClass = MyConformingClass()
    }

    func perform() {
        print(conformingClass.usedProperty)
    }
}

let myClass = MyClass()
myClass.perform()
```

Here we can see that `MyProtocol` is itself used, and cannot be removed. However, since `unusedProperty` is never called on `MyConformingClass`, Periphery is able to identify that the declaration of `unusedProperty` in `MyProtocol` is thus also unused and can be removed along with the unused implementation of `unusedProperty`.

### Assign-only Properties

Properties which are assigned to but never read from can be identified as unused by Periphery. However, since an unread property may be a valid use-case, e.g to purposefully retain the object, this identification is only enabled with [Aggressive Mode](#aggressive-mode).

```swift
class MyClass {
    static func make() -> Self {
        return self.init(myDependency: inject())
    }

    private let myDependency: MyDependency // 'myDependency' is unused

    init(myDependency: MyDependency) {
        self.myDependency = myDependency
    }

    func someMethod() {
    }
}
```

Note that this analysis only applies to simple properties, i.e properties do not define a custom getter or setter.

Removal of unused dependencies can reduce redundant incremental recompilation. The Swift compiler keeps track of every type that a source file exports, and uses (in `.swiftdeps` files). When a source file changes, any files that depend upon the changed types must also be recompiled. In this example, if `MyDependency` is declared in another file, and that file is changed, then the file containing `MyClass` will be needlessly recompiled.

As with any aggressive analysis technique, you should consider that the property might be needed solely to retain the instance. If the unread property is in fact needed, then this is a friendly reminder that you should add a comment explaining why.

### Enumerations

Along with being able to identify unused enumerations, Periphery can also identify individual unused enum cases. Plain enums that are not raw representable, i.e that _don't_ have a `String`, `Character`, `Int` or floating-point value type can be reliably identified. However, enumerations that _do_ have a raw value type can be dynamic in nature, and thus their identification is restricted to [Aggressive Mode](#aggressive-mode) only.

Let's clear this up with a quick example:

```swift
enum MyEnum: String {
    case myCase
}

func someFunction(value: String) {
    if let myEnum = MyEnum(rawValue: value) {
        somethingImportant(myEnum)
    }
}
```

Since `MyEnum` has a raw value type of `String`, `myCase` is only identified as unused when using aggressive analysis. There's no direct reference to the case, so it's reasonable to expect it _might_ no longer be needed, however if it were removed we can see that `somethingImportant` would never be called if `someFunction` were passed the value of `"myCase"`. Therefore more scrutiny is advised when using aggressive analysis and reviewing unused enum cases.

### Objective-C

Since Objective-C can use dynamic types, Periphery cannot reason about it from a static standpoint. Therefore, by default, Periphery will assume that any declaration exposed to Objective-C is in use. If your project is 100% Swift, then you can disable this behavior with the `--no-retain-objc-annotated` option. For those using Periphery on a mixed project, there are some important implications to be aware of.

As you already know, any declaration that is annotated with `@objc` or `@objcMembers` is exposed to the Objective-C runtime, and Periphery will assume they are in use. However, you should also be aware that any `class` that inherits from `NSObject` is also _implicitly_ exposed to Objective-C. If you ever come across a situation where Periphery reports that all methods and properties within a `class` - but not the `class` itself - are unused, then the class likely inherits from `NSObject`. It may be worth your time doing a cursory run of Periphery with `--no-retain-objc-annotated`, you may find a few extra declarations to remove. Though be warned, many declarations reported as unused may still be in use by Objective-C code, so you'll need to take extra care when reviewing them.

### Global Equatable Operators

Periphery is currently unable to identify if an Equatable infix operator is in use if it is defined at global scope. For example:

```swift
class MyClass: Equatable {}

func == (lhs: MyClass, rhs: MyClass) -> Bool {
    return true
}
```

Therefore, by default, Periphery will assume all global Equatable infix operators are in use. However, when operating in [Aggressive Mode](#aggressive-mode), such operators will be reported as _unused_. Clearly, false negative results are unwanted, so you can resolve this by moving the operator within the class, or into an extension.

```swift
class MyClass {}

extension MyClass: Equatable {
    static func == (lhs: MyClass, rhs: MyClass) -> Bool {
        return true
    }
}
```

### Aggressive Mode

By default Periphery aims to only report declarations that are safe to remove. In practice however, there are some scenarios in which code has a very high likelihood of being unused, but which cannot be guaranteed by static analysis alone. Such analysis techniques that may produce false negatives must be enabled explicitly.

To enable aggressive analysis:

```
periphery scan --aggressive ...
```

> **Beware**
>
> More scrutiny is advised when reviewing results produced by aggressive analysis. Some results may appear at first glance to be unused, and indeed your application may compile successfully after removal, however you should keep in mind how the removal might affect dynamic runtime behavior. With great power comes great responsibility!

The following scenarios are identified with aggressive analysis:


* [Assign-only properties](#assign-only-properties)
* [Unused raw value enumeration cases](#enumerations)
* [Global Equatable operators](#global-equatable-operators)

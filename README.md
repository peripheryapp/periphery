<h1>
  <img src="assets/logo.png" alt="Periphery" width="289" height="60">
</h1>

> A tool to identify unused code in Swift projects.

<a href="https://github.com/peripheryapp/periphery/actions">
  <img src="https://github.com/peripheryapp/periphery/workflows/Test/badge.svg?branch=master&event=push">
</a>
<a href="https://github.com/peripheryapp/periphery/releases/latest">
  <img src="https://img.shields.io/github/release/peripheryapp/periphery.svg" />
</a>

<br>

## Contents

- [Installation](#installation)
- [How To Use](#how-to-use)
- [How It Works](#how-it-works)
- [Analysis](#analysis)
  - [Function Parameters](#function-parameters)
  - [Protocols](#protocols)
  - [Enumerations](#enumerations)
  - [Objective-C](#objective-c)
- [Xcode Integration](#xcode-integration)
- [Excluding Files](#excluding-files)
- [Reusing Build Logs](#reusing-build-logs)
- [Troubleshooting](#troubleshooting)

## Installation

### [CocoaPods](https://cocoapods.org/)

Add the following to your Podfile:

```
pod 'Periphery'
```

Now run `pod install`, the Periphery executable will be downloaded and placed at `Pods/Periphery/periphery`.

### [Homebrew](https://brew.sh/)

Install Homebrew:

> You can skip this step if you already have Homebrew installed.

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Now that Homebrew is installed, we need to tell it where to find Periphery releases:

```
brew tap peripheryapp/periphery
```

Now install Periphery itself:

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

### Enumerations

Along with being able to identify unused enumerations, Periphery can also identify individual unused enum cases. Plain enums that are not raw representable, i.e that _don't_ have a `String`, `Character`, `Int` or floating-point value type can be reliably identified. However, enumerations that _do_ have a raw value type can be dynamic in nature, and therefore must be assumed to be used.

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

There's no direct reference to the `myCase` case, so it's reasonable to expect it _might_ no longer be needed, however if it were removed we can see that `somethingImportant` would never be called if `someFunction` were passed the value of `"myCase"`.

### Objective-C

Since Objective-C can use dynamic types, Periphery cannot reason about it from a static standpoint. Therefore, by default, Periphery will assume that any declaration exposed to Objective-C is in use. If your project is 100% Swift, then you can disable this behavior with the `--no-retain-objc-annotated` option. For those using Periphery on a mixed project, there are some important implications to be aware of.

As you already know, any declaration that is annotated with `@objc` or `@objcMembers` is exposed to the Objective-C runtime, and Periphery will assume they are in use. However, you should also be aware that any `class` that inherits from `NSObject` is also _implicitly_ exposed to Objective-C. If you ever come across a situation where Periphery reports that all methods and properties within a `class` - but not the `class` itself - are unused, then the class likely inherits from `NSObject`. It may be worth your time doing a cursory run of Periphery with `--no-retain-objc-annotated`, you may find a few extra declarations to remove. Though be warned, many declarations reported as unused may still be in use by Objective-C code, so you'll need to take extra care when reviewing them.

## Xcode Integration

Before setting up Xcode integration, we highly recommend you first get Periphery working in a terminal, as you will be using the exact same command via Xcode.

### Step 1: Create an Aggregate Target

Select your project in the Project Navigator and click the + button at the bottom left of the Targets section. Select **Cross-platform** and choose **Aggregate**. Hit Next.

![Step 1](assets/xcode-integration/1.png)

Choose a name for the new target, e.g "Periphery" or "Unused Code".

![Step 2](assets/xcode-integration/2.png)

### Step 2: Add a Run Script Build Phase

In the **Build Phases** section click the + button to add a new Run Script phase.

![Step 3](assets/xcode-integration/3.png)

In the shell script window enter the Periphery command. Be sure to include the `--format xcode` option.

![Step 4](assets/xcode-integration/4.png)

### Step 3: Select & Run

You're ready to roll. You should now see the new scheme in the dropdown. Select it and hit run.

> **Tip**
>
> If you'd like others on your team to be able to use the scheme, you'll need to mark it as _Shared_. This can be done by selecting _Manage Schemes..._ and selecting the _Shared_ checkbox next to the new scheme. The scheme definition can now be checked into source control.

![Step 5](assets/xcode-integration/5.png)

## Reusing Build Logs

In order to understand what reusing a build log means exactly, you first need to understand a little about how Periphery works, or more specifically, how SourceKit works. Periphery uses SourceKit to 'index' each Swift file, or in other words, translate it into a machine-readable format containing a high degree of detail, and crucially the references between declarations. In order to request this indexed format from SourceKit, Periphery must provide the Swift compiler arguments required to compile the file. In practice, this set of compiler arguments is the same as is needed to build the target which the file is a member of. Frustratingly, SourceKit does not provide an easy way to determine the appropriate compiler arguments needed for any given file. That's why Periphery must build your project - to spy on xcodebuild and extract the arguments passed to the Swift compiler.

Periphery allows you to save build logs so that you may skip the build phase, and jump straight to indexing. This can be a huge time saver while you're iterating on removing unused code, or when using Periphery in a continuous integration environment. To generate a build log, you have two options: allow Periphery to save one, or save your own by redirecting xcodebuild output to a log.

### Using Periphery's Build Logs

Pass the `--save-build-log <key>` option to the `scan` command, and Periphery will save a build log for you. You can then reuse it with the `--use-build-log <key>` option. The key can be anything you wish, however it is hashed along with the project, schemes and targets you specify. For example, you cannot save a build log, add another target to the `--targets` option and attempt to reuse the same build log.

### Using Your Own Build Logs

In a situation where you have already just compiled your project, e.g in CI to run tests, you can save yourself some time by passing the build log to Periphery. In order to do so, you'll need to redirect the output of xcodebuild to a file You need to be sure that the xcodebuild command builds all of the targets that you're then going to ask Periphery to analyze, otherwise Periphery will complain about missing build arguments. If your build process requires multiple calls to xcodebuild, just append the output to the same file. Once you have the build log, you can instruct Periphery to use it by passing the `--use-build-log <path to log>` option to the `scan` command. The build log must have a `.log` extension to distinguish it from a `<key>` as described above.

> **Important - must read!**
>
> The build log contains highly specific references to DerivedData. Any modification to DerivedData after saving the build log, and before using it with Periphery is likely to invalidate the build log. Periphery will warn you as such if this has happened. Therefore, reusing build logs is only suitable for situations where you intend to use the log immediately after it has been generated. You cannot save a build log on one machine and reuse it on another, as SourceKit depends upon the contents of DerivedData to index files.

## Excluding Files

Both exclusion options described below accept a path glob, either absolute or relative to your project directory. You may specify multiple globs by separating them with a pipe character, e.g `"Foo.swift|{Bar,Baz}.swift|path/to/*.swift"`. Recursive (`**`) globs are not supported at this time.

### Excluding Results

To exclude the results from certain files, pass the `--report-exclude <globs>` option to the `scan` command.

### Excluding Indexed Files

To exclude files from being indexed, pass the `--index-exclude <glob>` option to the `scan` command. Excluding files from the index phase means that any declarations and references contained within the files will not be seen by Periphery. Periphery will be behave as if the files do not exist. This option can be used to exclude generated code that holds references to non-generated code.

## Troubleshooting

#### Failed to determine build arguments for target 'XYZ'

This is caused by something specific to your project and is likely caused by Periphery failing to correctly parse swiftc compiler arguments from the xcodebuild log.

Please re-run Periphery with the `--verbose` option and open an issue with the full output.

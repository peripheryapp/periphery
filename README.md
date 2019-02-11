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
  <a href="#how-it-works">How It Works</a>
</p>

<p align="center">
<hr>
Periphery was previously a closed-source product, and is still in the process of transitioning to an open-source environment. Please bare with us while the project and its various components are migrated.
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

The scan command is Periphery's primary function. To begin an interactive guided setup, simply change to your project directory and run:

```
periphery scan
```

After answering a few questions, Periphery will print out the full scan command with appropriate arguments for your project, and execute it.

## How It Works

Periphery first builds all of the schemes provided via the `--schemes` option using `xcodebuild`. It then indexes all files that are members of the targets passed to the `--targets` option, resulting in a graph of declarations and references. Finally, it performs numerous mutations on the graph then analyzes it to identify unused declarations.

For example, if your Xcode workspace consists of a single application and multiple frameworks all defined in separate projects, you'd choose a scheme that builds the application and framework targets. Typically any dependent frameworks would be built implicitly if they're used by the application, so you'd likely only need to specify your application's main scheme.

It's important to specify a complete set of targets for the `--targets` option. For the example above, we'd need to specify the application target, and each framework target. If you did not include your application target, then Periphery would correctly identify that many public interfaces of your frameworks are unused.

The scan options for this example would be as follows:

```
periphery scan --workspace MyApp.xcworkspace --schemes MyApp --targets MyApp,FrameworkA,FrameworkB --format xcode
```

If your project consists of one or more standalone frameworks that do not also contain some kind of application that consume their interfaces, then you'll need to tell Periphery to assume that all public declarations are in fact used by including the `--retain-public` option.

If your project is 100% Swift, then you'll likely want to include the `--no-retain-objc-annotated` option. For projects that are mixed Objective-C/Swift, we highly recommend you [read about the implications](#) this can have on your results.

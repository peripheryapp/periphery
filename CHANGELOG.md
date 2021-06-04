## master

##### Breaking

- None.

##### Enhancements

- Using an index store that does not contain complete data for the requested targets now results in an error.
- The '--index-store-path' option now implies '--skip-build'.

##### Bug Fixes

- None.

## 2.5.2 (2021-06-03)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix erroneous results for explicit 'getter' accessors.

## 2.5.1 (2021-06-02)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix an issue where scans with many schemes could breaking loading of the index store.

## 2.5.0 (2021-05-27)

##### Breaking

- None.

##### Enhancements

- Add redundant public accessibility analysis.
- Add arm64 support.
- Add `--retain-assign-only-property-types` option to retain assign-only properties based on their type.
- Declarations in an entry point file (e.g main.swift) are no longer blindly retained, even if unused.
- Additional arguments passed to xcodebuild can now override the default set of environment based arguments.

##### Bug Fixes

- Fix issue where protocol property references could be incorrectly associated with the getter/setter rather than the property itself, leading to erroneous results.
- Fix unused parameter false positive result for identical function signatures at the same location in different files.

## 2.4.3 (2021-03-05)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Retain constructors of generic structs that cannot be identified as used due to Swift bug SR-7093.

## 2.4.2 (2021-02-11)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- In Swift 5.3 and lower, all optional protocol members are now retained in order to workaround a Swift bug. This bug is resolved in Swift 5.4.
- Cases of public enums are now also retained when using `--retain-public`.
- Open method parameters are now also retained when using `--retain-public`.
- Empty public protocols that have an implementation in extensions are no longer identified as redundant.
- Foreign protocol method parameters are no longer identified as unused.

## 2.4.1 (2020-12-20)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix ignore comments on protocol declarations.

## 2.4.0 (2020-12-19)

##### Breaking

- The `--xcargs` option has been removed, and superseded by passing arguments following the `--` terminator. E.g `periphery scan --xcargs --foo` is now `periphery scan -- --foo`. This feature can also be used to pass arguments to `swift build` for SwiftPM projects.

##### Enhancements

- None.

##### Bug Fixes

- None.

## 2.3.3 (2020-12-17)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Improve unused parameter location identification.

## 2.3.2 (2020-12-10)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix indexing failure on unhandled declaration kinds, such as 'commentTag'.
- `--retain-objc-accessible` also retains private declarations explicitly attributed with `@objc`.

## 2.3.1 (2020-12-06)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix crash during indexing phase.

## 2.3.0 (2020-12-05)

##### Breaking

- JSON and CSV output formats have changed to reflect the fact that declarations can have multiple IDs if they're members of multiple build targets.
- Declarations accessible by the Objective-C runtime are no longer retained by default. The `--no-retain-objc-annotated` option has been removed, and `--retain-objc-accessible` added.

##### Enhancements

- Protocols that are never used as an existential type are now explicitly identified as redundant rather than simply unused, which could be confusing.
- Add `--clean-build` flag to clean build artifacts before the build step.
- Add support for files that are members of multiple build targets. Such files no longer produce erroneous results.

##### Bug Fixes

- Protocol members whose implementation is provided by an external type, yet aren't referenced via a value type are now identified as unused.
- @IBInspectable properties are now retained.
- Declarations ignored with a '// periphery:ignore' comment now also retain their references to other declarations.
- Fix running Periphery from within Xcode where Xcode's environment variables could cause build failures or incorrect results.
- Fix an issue where a protocol could incorrectly retain references to methods in an unused conforming declaration.

## 2.2.2 (2020-11-23)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Extension classes referenced in Info.plist as NSExtensionPrincipalClass are now retained.

## 2.2.1 (2020-11-22)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix unused parameter identification when surrounded with backquotes.

## 2.2.0 (2020-11-21)

##### Breaking

- None.

##### Enhancements

- Add support for SwiftPM & Xcode mixed projects.

##### Bug Fixes

- None.

## 2.1.1 (2020-11-18)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- IBOutlets and IBActions that reside in a base class that are referenced only via a subclass are now retained.

## 2.1.0 (2020-11-14)

##### Breaking

- None.

##### Enhancements

- Added a Checkstyle output formatter.

##### Bug Fixes

- Fix Swift 5.2 support.
- Updated Yams dependency to fix building with Swift for Tensorflow.
- Fix possible concurrent mutation crash.
- Classes & structs that conform to SwiftUI's LibraryContentProvider are now retained.

## 2.0.1 (2020-11-10)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix version number.

## 2.0.0 (2020-11-10)

##### Breaking

- SourceKit based indexing has been removed, the IndexStore indexer is now the sole indexer. Therefore, the following scan options have been removed: `--use-index-store`, `--use-build-log`, `--save-build-log`.
- The `scan-syntax` command has been removed.

##### Enhancements

- Support for code comments to ignore unused declarations.
- Support for analyzing Swift Package Manager projects.
- Linux support for Swift Package Manager projects.
- Assign-only property detection is back and enabled by default. Disable it with `--retain-assign-only-properties`.
- Added `--skip-build` option to skip the build phase.

##### Bug Fixes

- UISceneDelegateClassName & UISceneClassName referenced in Info.plist are now retained.
- Ignore parameters from functions annotated with @IBAction.
- Classes & structs that conform to SwiftUI's PreviewProvider are now retained.
- Support @main entry points.
- Fix unused recursive function detection when using the index store.
- Properties named in struct implicit constructors are now retained.
- Implicit declarations such as struct constructors are now retained.
- A `typealias` that defines an `associatedtype` in an external protocol is now retained.
- All custom `appendInterpolation` methods are now retained, as they cannot be identified as unused due to https://bugs.swift.org/browse/SR-13792.
- Fixed path resolution for nested projects in Xcode workspaces.
- `wrappedValue` and `projectedValue` properties in property wrappers are now retained.
- `XCTestManifests.swift` is now treated as an entry point file like `LinuxMain.swift`.
- Updated `XcodeProj` dependency to resolve some Xcode project parsing issues.

## 1.8.0 (2020-10-3)

##### Breaking

- Aggressive Mode has been removed as it provided little value.
- Removed undocumented diagnosis console feature.

##### Enhancements

- Add Xcode 12 support.

##### Bug Fixes

- Fixed an issue where implicit declarations inserted by SourceKit could cause incorrect results.

## 1.7.1 (2020-04-18)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix --exclude option for scan-syntax.
- Bundle lib_InternalSwiftSyntaxParser.dylib in the release archive.

## 1.7.0 (2020-04-17)

##### Breaking

- None.

##### Enhancements

- Support for Xcode 11.4, Swift 5.2.
- Experimental IndexStore based indexer.

##### Bug Fixes

- Fix shell escaping issues.

## 1.6.0 (2020-03-28)

##### Breaking

- None.

##### Enhancements

- Add support for Xcode 11.3.

##### Bug Fixes

- None.

## 1.5.1 (2019-07-06)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix CocoaPod.

## 1.5.0 (2019-07-06)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Xcode 10.2 compatibly.

## 1.4.0 (2019-03-02)

##### Breaking

- None.

##### Enhancements

- New `strict` option to exit with non-zero status if any unused code is found.
  [Cihat Gündüz](https://github.com/Dschee)
  [#22](https://github.com/peripheryapp/periphery/issues/22)
  [#23](https://github.com/peripheryapp/periphery/pull/23)

- Add official Homebrew support.
  [Ian Leitch](https://github.com/ileitch)
  [#24](https://github.com/peripheryapp/periphery/pull/24)

##### Bug Fixes

- Fix parsing of projects using Siri message intents.
  [Ian Leitch](https://github.com/ileitch)
  [#25](https://github.com/peripheryapp/periphery/issues/25)
  [#26](https://github.com/peripheryapp/periphery/pull/26)

## 1.3.0 (2019-02-10)

##### Breaking

- First open-source release.

##### Enhancements

- None.

##### Bug Fixes

- None.

## 1.2.3 (2019-01-05)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Don't attempt to syntax scan directories ending with .swift.
- Detect invalid xcodeproj references.

## 1.2.2 (2018-12-19)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix infinate loop from parsing projects with cyclic references.

## 1.2.1 (2018-12-12)

##### Breaking

- None.

##### Enhancements

- Improve performance of scan-syntax command.

##### Bug Fixes

- Fix parsing of #warning and #error directives.

## 1.2.0 (2018-12-11)

##### Breaking

- None.

##### Enhancements

- Unused function prameter analysis.
- Terminate all child processes on SIGINT.
- Exclude pod schemes from guided setup.
- Remove retain ObjC question from guided setup.

##### Bug Fixes

- Avoid passing 'CURRENT_ARCH' and 'arch' environment variables to xcodebuild when their value is 'undefined_arch'.

## 1.1.3 (2018-11-10)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Improved target module name identification.

## 1.1.2 (2018-10-31)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix crash when inspecting project configuration for nested .xcodeproj.
- Detect .xcodeproj referenced from within groups in an .xcworkspace.

## 1.1.1 (2018-10-26)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Projects nested within other projects are now identified.

## 1.1.0 (2018-10-29)

##### Breaking

- None.

##### Enhancements

- Label results identified by aggressive mode.
- Add compiler flags to speed up build phase.
- Schemes are built in the order they're given.
- Add error hint for CocoaPods bug #8000.
- Add support for YAML configuration.

##### Bug Fixes

- Retain XCTestCase classes that do not directly inherit XCTestCase.

## 1.0.0 (2018-10-20)

##### Breaking

- None.

##### Enhancements

- No more trial mode - 100% of results are now free. Advanced features require a Pro license.

##### Bug Fixes

- Fixed issue with poor performance resulting in a segmentation fault.

## 0.12.2 (2018-09-27)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Ensures Xcode is configured for command-line use.

## 0.12.1 (2018-09-26)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Built with a static Swift stdlib.
- Ignore xcworkspace generated by Swift Package Manager inside the xcodeproj.

## 0.12.0 (2018-09-24)

##### Breaking

- None.

##### Enhancements

- Support for saving, and using build logs in order to skip the build phase.
- All output format types are now available in trial mode.

##### Bug Fixes

- Unused code with cyclic dependencies is now detected.
- Protocol declarations implemented in a subclass of the conforming class are now identified as used.
- Protocols that inherit a foreign protocol (e.g from Foundation) are now treated differently than other protocols, as Periphery cannot detect declarations that are used internally by the foreign module. For example, if your class conforms to Comparable and implements <(lhs:rhs:), the behavior of sort() may be altered, yet Periphery does not have visibility of any directs call to <(lhs:rhs:).

## 0.11.2 (2018-08-07)

##### Breaking

- None.

##### Enhancements

- --report-exclude and --index-exclude options now expect a pipe character to delimit multiple globs.

##### Bug Fixes

- None.

## 0.11.1 (2018-08-06)

##### Breaking

- None.

##### Enhancements

- Identify LinuxMain.swift as an entry point.

##### Bug Fixes

- Fix regression of handling schemes and targets containing spaces.

## 0.11.0 (2018-08-04)

##### Breaking

- None.

##### Enhancements

- Added tips for eliminating false positives in trial mode.
- Added check-update command.
- Added ability to exclude files either from indexing or final report.

##### Bug Fixes

- None.

## 0.10.0 (2018-07-10)

##### Breaking

- None.

##### Enhancements

- Added support for Xcode 10.
- Warn about source files that are members of multiple targets.
- Diagnosis console now lists active references as their source location.

##### Bug Fixes

- Fixed issue where error messages would not be printed before Periphery exits.

## 0.9.0 (2018-06-22)

##### Breaking

- None.

##### Enhancements

- Added guided setup flow.

##### Bug Fixes

- None.

## 0.8.1 (2018-06-13)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Handle explicitly defined PRODUCT_MODULE_NAME.

## 0.8.0 (2018-06-12)

##### Breaking

- None.

##### Enhancements

- Added support for Xcode's new build system.
- Added support for analyzing XCTest targets.
- Added interactive diagnosis console, enabled with the --diagnose option.
- Licenses can now be activated using --email and --key options instead of entering them interactively.

##### Bug Fixes

- Improve parsing of xcodebuild -list output.
- Type aliases that define an associated type are now identified as used.

## 0.7.3 (2018-05-11)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Workaround issue with xcodebuild using non-UTF8 encoding.

## 0.7.2 (2018-05-03)

##### Breaking

- None.

##### Enhancements

- Enable analysis of CocoaPod targets.

##### Bug Fixes

- None.

## 0.7.1 (2018-05-01)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Improve scheme identification for older workspaces.
- Fix handling of source files containing single quotes.
- Fix handling of paths to swiftc that contain hyphens e.g Xcode-9.3.app.

## 0.7.0 (2018-04-29)

##### Breaking

- None.

##### Enhancements

- Disabled code signing as it's not necessary and can cause build failures.
- Schemes are no longer required to be marked as shared in order to be discovered.

##### Bug Fixes

- Fixed discovery of xibs/storyboards that reside within a Base.jproj.
- Fix retention of protocol declarations with a default implementation within an extension.

## 0.6.2 (2018-04-26)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Correctly handle projects containing spaces their PRODUCT_NAME.
- Add support for missing declaration kinds.

## 0.6.1 (2018-04-25)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Improve xcodebuild swiftc argument parsing such that CoreData generated model file arguments are retained.
- Improved invalid scheme error message.

## 0.6.0 (2018-04-21)

##### Breaking

- None.

##### Enhancements

- Added trial mode.

##### Bug Fixes

- None.

## 0.5.0 (2018-04-17)

##### Breaking

- The --retain-all-enum-cases option has been removed. Unused cases of enums that are not raw representable are always identified. Unused cases of raw representable enums are now implicitly used since their use may be completely dynamic. --aggressive analysis disables this implicit behavior.
- The --retain-objc-annotated option is now enabled by default.

##### Enhancements

- Xcode format output is colored to improve readability.

##### Bug Fixes

- CodingKey enums are now correctly identified as used if the enclosing class or struct conforms to Decodable.

## 0.4.0 (2018-04-16)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix retention of declarations marked @IBOutlet or @IBAction.

## 0.3.0 (2018-04-14)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Fix issue parsing Xcode projects that contained groups without an associated physical directory.

## 0.2.0 (2018-04-09)

##### Breaking

- None.

##### Enhancements

- None.

##### Bug Fixes

- Added --project option for use with projects that do not have an .xcworkspace.

## 0.1.0 (2018-04-07)

- Initial release.

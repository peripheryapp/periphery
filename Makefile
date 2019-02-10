SWIFT_BUILD_FLAGS=-Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"

.PHONY: all $(MAKECMDGOALS)

all: build

build:
	@swift build $(SWIFT_BUILD_FLAGS)

release:
	@swift build -c release -Xswiftc -static-stdlib $(SWIFT_BUILD_FLAGS)

proj: build
	@rm -rf Periphery.xcodeproj
	@swift package generate-xcodeproj --xcconfig-overrides Sources/Configs/Periphery.xcconfig
	@cp Tests/Configs/RetentionFixtures.xcscheme Periphery.xcodeproj/xcshareddata/xcschemes/
	@open Periphery.xcodeproj

lint:
	@swiftlint lint --quiet

test:
	@swift test $(SWIFT_BUILD_FLAGS)
